"""Rewrite the audio of the media library so the LG C2 plays it directly.

The TV has no DTS decoder. For a DTS track Jellyfin copies the video into
HLS and transcodes only the audio, and the TV's own HLS player stalls on
those segments, which follow the source's uneven keyframes. So every DTS
track becomes AC3. Audio that is not English, Russian or the title's
original language (from Sonarr/Radarr) is dropped, unless the release
marks it as the original; when the original language is unknown, nothing
is dropped.

Each file is written next to the original as a hidden temp file, checked
with ffprobe, then renamed over it. Video, subtitles, chapters and
attachments are copied untouched.
"""

import argparse
import datetime
import json
import os
import stat
import subprocess
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOTS = ["/mnt/Media/Movies", "/mnt/Media/TV Shows"]
ALWAYS_KEEP = {"eng", "rus"}
UNDETERMINED = {"", "und", "mul", "mis", "zxx"}
ORIGINAL_WORDS = ("original", "оригинал")
CONVERT_CODECS = {"dts"}
TMP_SUFFIX = ".audiofix.tmp"
# Files touched more recently may still be mid-import by Sonarr/Radarr.
MIN_AGE_SECONDS = 3600
DURATION_TOLERANCE = 2.0
STAT_TAGS = [
    "BPS", "DURATION", "NUMBER_OF_FRAMES", "NUMBER_OF_BYTES",
    "_STATISTICS_WRITING_APP", "_STATISTICS_WRITING_DATE_UTC",
    "_STATISTICS_TAGS",
]

# Track tags come as ISO 639-1, 639-2/B or 639-2/T; all fold to 639-2/B.
ALIASES = {
    "en": "eng", "ru": "rus", "fr": "fre", "fra": "fre", "de": "ger",
    "deu": "ger", "es": "spa", "it": "ita", "ja": "jpn", "ko": "kor",
    "zh": "chi", "zho": "chi", "cmn": "chi", "yue": "chi", "pt": "por",
    "nl": "dut", "nld": "dut", "sv": "swe", "da": "dan", "no": "nor",
    "nb": "nor", "nob": "nor", "nn": "nor", "nno": "nor", "fi": "fin",
    "pl": "pol", "cs": "cze", "ces": "cze", "hu": "hun", "el": "gre",
    "ell": "gre", "tr": "tur", "he": "heb", "ar": "ara", "hi": "hin",
    "th": "tha", "uk": "ukr", "fa": "per", "fas": "per", "is": "ice",
    "isl": "ice", "ro": "rum", "ron": "rum", "bg": "bul", "sr": "srp",
    "hr": "hrv", "vi": "vie", "id": "ind", "ms": "may", "msa": "may",
    "ta": "tam", "te": "tel", "bn": "ben", "lt": "lit", "lv": "lav",
    "et": "est", "sk": "slo", "slk": "slo", "sl": "slv", "ca": "cat",
    "ka": "geo", "kat": "geo", "sq": "alb", "sqi": "alb", "mk": "mac",
    "mkd": "mac", "bs": "bos", "ur": "urd", "tl": "tgl", "fil": "tgl",
}

# Sonarr/Radarr language names to 639-2/B.
NAMES = {
    "English": "eng", "Russian": "rus", "French": "fre", "German": "ger",
    "Spanish": "spa", "Spanish (Latino)": "spa", "Italian": "ita",
    "Japanese": "jpn", "Korean": "kor", "Chinese": "chi",
    "Cantonese": "chi", "Mandarin": "chi", "Portuguese": "por",
    "Portuguese (Brazil)": "por", "Dutch": "dut", "Flemish": "dut",
    "Swedish": "swe", "Danish": "dan", "Norwegian": "nor",
    "Finnish": "fin", "Polish": "pol", "Czech": "cze", "Hungarian": "hun",
    "Greek": "gre", "Turkish": "tur", "Hebrew": "heb", "Arabic": "ara",
    "Hindi": "hin", "Thai": "tha", "Ukrainian": "ukr", "Persian": "per",
    "Icelandic": "ice", "Romanian": "rum", "Bulgarian": "bul",
    "Serbian": "srp", "Croatian": "hrv", "Vietnamese": "vie",
    "Indonesian": "ind", "Malay": "may", "Tamil": "tam", "Telugu": "tel",
    "Bengali": "ben", "Lithuanian": "lit", "Latvian": "lav",
    "Estonian": "est", "Slovak": "slo", "Slovenian": "slv",
    "Catalan": "cat", "Georgian": "geo", "Albanian": "alb",
    "Macedonian": "mac", "Bosnian": "bos", "Urdu": "urd", "Tagalog": "tgl",
}


def log(message):
    print(message, flush=True)


def norm(code):
    code = (code or "").strip().lower().split("-")[0]
    return ALIASES.get(code, code)


def arr_titles(config_xml, endpoint):
    """Map each Sonarr/Radarr title folder to its original language code."""
    root = ET.parse(config_xml).getroot()
    key = root.findtext("ApiKey")
    port = root.findtext("Port")
    base = (root.findtext("UrlBase") or "").rstrip("/")
    url = f"http://127.0.0.1:{port}{base}/api/v3/{endpoint}"
    request = urllib.request.Request(url, headers={"X-Api-Key": key})
    with urllib.request.urlopen(request, timeout=60) as response:
        items = json.load(response)
    folders = {}
    for item in items:
        name = (item.get("originalLanguage") or {}).get("name")
        if item.get("path") and name in NAMES:
            folders[item["path"].rstrip("/")] = NAMES[name]
    return folders


def load_languages(configs):
    folders = {}
    for config_xml, endpoint in configs:
        try:
            folders.update(arr_titles(config_xml, endpoint))
        except (OSError, ValueError, ET.ParseError) as error:
            log(f"warning: no original languages from {config_xml}: {error}")
    return folders


def original_language(path, folders):
    for parent in Path(path).parents:
        if str(parent) in folders:
            return folders[str(parent)]
    return None


def probe(path):
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_streams", "-show_format",
         "-of", "json", path],
        capture_output=True, text=True, check=True,
    )
    return json.loads(result.stdout)


def lang(stream):
    return norm((stream.get("tags") or {}).get("language"))


def marked_original(stream):
    """The release says this is the original audio, whatever the *arr thinks.

    Radarr has The Passion of the Christ as English; its Aramaic track is
    titled "Original DTS".
    """
    title = ((stream.get("tags") or {}).get("title") or "").lower()
    flagged = (stream.get("disposition") or {}).get("original")
    return bool(flagged) or any(word in title for word in ORIGINAL_WORDS)


def wanted_track(stream, wanted):
    if wanted is None or marked_original(stream):
        return True
    return lang(stream) in UNDETERMINED or lang(stream) in wanted


def plan(streams, original):
    """Return (kept stream indexes, indexes to encode as AC3), or None."""
    audio = [s for s in streams if s["codec_type"] == "audio"]
    wanted = None if original is None else ALWAYS_KEEP | {original}
    kept = [s for s in audio if wanted_track(s, wanted)]
    if not kept:
        kept = audio
    # Same-language DTS tracks are often different dubs or commentaries,
    # so each one is converted rather than dropped as a duplicate.
    convert = {s["index"] for s in kept if s["codec_name"] in CONVERT_CODECS}
    if len(kept) == len(audio) and not convert:
        return None
    dropped = {s["index"] for s in audio} - {s["index"] for s in kept}
    keep = [s["index"] for s in streams if s["index"] not in dropped]
    return keep, convert


def encode_args(out, stream):
    channels = stream.get("channels") or 2
    args = [f"-c:{out}", "ac3", f"-b:{out}", "640k" if channels > 2 else "256k"]
    if channels > 6:
        args += [f"-ac:{out}", "6"]
    title = (stream.get("tags") or {}).get("title") or ""
    if "dts" in title.lower():
        args += [f"-metadata:s:{out}", "title="]
    for tag in STAT_TAGS:
        for key in (tag, f"{tag}-eng"):
            args += [f"-metadata:s:{out}", f"{key}="]
    return args


def ffmpeg_command(path, tmp, streams, keep, convert):
    by_index = {s["index"]: s for s in streams}
    args = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
            "-y", "-i", path]
    for index in keep:
        args += ["-map", f"0:{index}"]
    args += ["-c", "copy"]
    for out, index in enumerate(keep):
        if index in convert:
            args += encode_args(out, by_index[index])
    audio_out = [o for o, i in enumerate(keep) if by_index[i]["codec_type"] == "audio"]
    if audio_out and not any(by_index[keep[o]]["disposition"].get("default") for o in audio_out):
        args += [f"-disposition:{audio_out[0]}", "default"]
    args += ["-default_mode", "passthrough", "-max_interleave_delta", "0",
             "-f", "matroska", tmp]
    return args


def verify(tmp, source, keep, convert):
    result = probe(tmp)
    streams = result["streams"]
    if len(streams) != len(keep):
        return f"{len(streams)} streams, expected {len(keep)}"
    ac3 = sum(1 for s in streams if s["codec_name"] == "ac3")
    expected = sum(1 for s in source["streams"] if s["index"] in keep and s["codec_name"] == "ac3") + len(convert)
    if ac3 != expected:
        return f"{ac3} AC3 tracks, expected {expected}"
    before = float(source["format"].get("duration") or 0)
    after = float(result["format"].get("duration") or 0)
    if abs(before - after) > DURATION_TOLERANCE:
        return f"duration {after:.1f}s, expected {before:.1f}s"
    return None


def describe(streams, keep, convert):
    parts = []
    for s in streams:
        if s["codec_type"] != "audio":
            continue
        name = f"{lang(s) or 'und'}:{s['codec_name']}{s.get('channels', '')}"
        if s["index"] not in keep:
            parts.append(f"-{name}")
        elif s["index"] in convert:
            parts.append(f"{name}>ac3")
    return " ".join(parts)


def rewrite(path, source, keep, convert):
    tmp = str(Path(path).with_name(f".{Path(path).name}{TMP_SUFFIX}"))
    free = os.statvfs(os.path.dirname(path))
    if free.f_bavail * free.f_frsize < os.path.getsize(path) * 1.2:
        raise RuntimeError("not enough free space for the temp file")
    try:
        subprocess.run(ffmpeg_command(path, tmp, source["streams"], keep, convert),
                       check=True, capture_output=True, text=True)
        problem = verify(tmp, source, keep, convert)
        if problem:
            raise RuntimeError(f"check failed: {problem}")
        os.chmod(tmp, stat.S_IMODE(os.stat(path).st_mode))
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)


def process(path, folders, dry_run):
    """Return True when the file was (or, dry, would be) rewritten."""
    source = probe(path)
    result = plan(source["streams"], original_language(path, folders))
    if result is None:
        return False
    keep, convert = result
    change = describe(source["streams"], keep, convert)
    if dry_run:
        log(f"would fix: {path} [{change}]")
        return True
    started = time.monotonic()
    rewrite(path, source, keep, convert)
    log(f"fixed in {time.monotonic() - started:.0f}s: {path} [{change}]")
    return True


def candidates(roots):
    now = time.time()
    for root in roots:
        for dirpath, _, filenames in os.walk(root):
            for name in sorted(filenames):
                path = os.path.join(dirpath, name)
                if name.startswith(".") and name.endswith(TMP_SUFFIX):
                    log(f"removing leftover temp file: {path}")
                    os.remove(path)
                elif name.lower().endswith(".mkv") and now - os.path.getmtime(path) > MIN_AGE_SECONDS:
                    yield path


def deadline_from(value):
    if not value:
        return None
    hour, minute = (int(part) for part in value.split(":"))
    now = datetime.datetime.now()
    limit = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
    return limit if limit > now else limit + datetime.timedelta(days=1)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="*", help="files to fix instead of the whole library")
    parser.add_argument("--dry-run", action="store_true", help="only print what would change")
    parser.add_argument("--deadline", help="HH:MM after which no new file is started")
    parser.add_argument("--sonarr-config", help="Sonarr config.xml, for original languages")
    parser.add_argument("--radarr-config", help="Radarr config.xml, for original languages")
    return parser.parse_args()


def main():
    args = parse_args()
    configs = [(c, e) for c, e in [(args.sonarr_config, "series"), (args.radarr_config, "movie")] if c]
    folders = load_languages(configs)
    log(f"original language known for {len(folders)} titles")
    deadline = deadline_from(args.deadline)
    counts = {"fixed": 0, "failed": 0}
    for path in args.paths or candidates(ROOTS):
        if deadline and datetime.datetime.now() >= deadline:
            log("deadline reached, the rest waits for the next run")
            break
        try:
            if process(path, folders, args.dry_run):
                counts["fixed"] += 1
        except (OSError, RuntimeError, ValueError, KeyError, subprocess.CalledProcessError) as error:
            detail = getattr(error, "stderr", "") or ""
            log(f"failed: {path}: {error} {detail.strip()[-500:]}")
            counts["failed"] += 1
    verb = "would fix" if args.dry_run else "fixed"
    log(f"done: {verb} {counts['fixed']}, failed {counts['failed']}")
    return 1 if counts["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())

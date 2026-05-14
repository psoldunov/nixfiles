{
  pkgs,
  config,
  ...
}: {
  convert_all_to_mkv = pkgs.writeShellScriptBin "convert_all_to_mkv" ''
    # Use the current working directory
    DIRECTORY=$(pwd)

    # Loop over all mp4 files in the directory
    for file in "$DIRECTORY"/*.mp4; do
      # Extract the filename without extension
      filename=$(basename -- "$file" .mp4)

      # Convert the file using Quick Sync
      ffmpeg -i "$file" -c:v h264_qsv -c:a copy "$DIRECTORY/$filename.mkv"

      # Check if the conversion was successful before deleting the original file
      if [ $? -eq 0 ]; then
        echo "Converted $file to $DIRECTORY/$filename.mkv successfully."

        # Delete the original file
        rm "$file"
      else
        echo "Failed to convert $file. Skipping deletion."
      fi
    done
  '';
}

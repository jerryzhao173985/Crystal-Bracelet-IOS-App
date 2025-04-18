import os

output_filename = "all_files_combined.txt"

with open(output_filename, 'w', encoding='utf-8') as outfile:
    for foldername, subfolders, filenames in os.walk("."):
        for filename in filenames:
            file_path = os.path.join(foldername, filename)
            if file_path == f"./{output_filename}":
                continue  # Skip the output file itself
            try:
                with open(file_path, 'r', encoding='utf-8') as infile:
                    relative_path = os.path.relpath(file_path, start='.')
                    outfile.write(f"\n{'='*80}\n")
                    outfile.write(f"FILE: {relative_path}\n")
                    outfile.write(f"{'-'*80}\n")
                    outfile.write(infile.read())
                    outfile.write(f"\n{'='*80}\n\n")
            except Exception as e:
                print(f"Could not read {file_path}: {e}")


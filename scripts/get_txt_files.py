import os

def collect_gd_files_to_txt(skills_folder, output_file):
    # Ensure the skills folder exists
    if not os.path.exists(skills_folder):
        print(f"Error: The folder '{skills_folder}' does not exist.")
        return

    # Open the output file for writing
    with open(output_file, 'w', encoding='utf-8') as txt_file:
        # Walk through the skills folder
        for root, _, files in os.walk(skills_folder):
            for file in files:
                if file.endswith('.gd'):
                    gd_file_path = os.path.join(root, file)
                    try:
                        # Read the content of the .gd file
                        with open(gd_file_path, 'r', encoding='utf-8') as gd_file:
                            content = gd_file.read()
                            # Write the content to the output file
                            txt_file.write(f"### {file} ###\n")
                            txt_file.write(content)
                            txt_file.write("\n\n")
                    except Exception as e:
                        print(f"Error reading file {gd_file_path}: {e}")

    print(f"All .gd files have been written to '{output_file}'.")

# Define the folder containing .gd files and the output file
skills_folder = './skills'
output_file = 'skills_combined.txt'

# Run the function
collect_gd_files_to_txt(skills_folder, output_file)
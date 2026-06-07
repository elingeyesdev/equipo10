import re

file_path = 'app/Http/Controllers/Api/ReporteController.php'

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Pattern 1
pattern1 = r'\$path = parse_url\(\$img->url, PHP_URL_PATH\);\s*\$fixedUrl = \$path \? request\(\)->getSchemeAndHttpHost\(\) \. \$path : \$img->url;'
code = re.sub(pattern1, r'$fixedUrl = $img->url;', code)

# Pattern 2
pattern2 = r'\$path = parse_url\(\$url, PHP_URL_PATH\);\s*\$fixedUrl = \$path \? request\(\)->getSchemeAndHttpHost\(\) \. \$path : \$url;'
code = re.sub(pattern2, r'$fixedUrl = $url;', code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Replaced successfully")

CodeCoverage.exe -e Tests.exe -m Tests.map -uf dcov_units.txt -sp "..\" -od "coverage" -lt -html
start coverage\CodeCoverage_summary.html

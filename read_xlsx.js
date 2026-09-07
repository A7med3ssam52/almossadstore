import xlsx from 'xlsx';
import fs from 'fs';

try {
    const workbook = xlsx.readFile('list.xlsx');
    const sheetA = workbook.Sheets[workbook.SheetNames[0]];
    const dataA = xlsx.utils.sheet_to_json(sheetA, { header: 1 });
    
    // Write the first 20 rows to a temp json file to see the structure
    fs.writeFileSync('temp_layout.json', JSON.stringify(dataA.slice(0, 20), null, 2));
    
    console.log("Successfully wrote temp_layout.json");
} catch (e) {
    console.error("Error reading file:", e.message);
}

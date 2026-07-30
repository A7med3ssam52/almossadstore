import xlsx from 'xlsx';
import fs from 'fs';

function escapeSql(str) {
    if (!str) return '';
    return str.replace(/'/g, "''");
}

async function run() {
  const workbook = xlsx.readFile('list.xlsx');
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = xlsx.utils.sheet_to_json(sheet, { header: 1 });
  
  if (rows.length < 2) return console.log("Empty sheet");

  const mainCategories = [];
  for (let c = 0; c < rows[0].length; c += 3) {
      if (rows[0][c]) {
          mainCategories.push({ name: rows[0][c].toString().trim(), colIdx: c });
      }
  }

  let sql = `-- Al Mossad Store Data Import SQL\n\n`;
  
  // Create Categories (Insert if not exists, but we can't easily get the UUID in pure SQL without PL/pgSQL).
  // Wait, we can insert and then insert products by looking up the category id with a subquery!
  
  for (const cat of mainCategories) {
      sql += `INSERT INTO public.categories (name) SELECT '${escapeSql(cat.name)}' WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = '${escapeSql(cat.name)}');\n`;
  }
  
  sql += `\n`;

  const productsToInsert = [];

  for (let r = 2; r < rows.length; r++) {
      const row = rows[r];
      if (!row || row.length === 0) continue;
      
      for (const cat of mainCategories) {
          const colIdx = cat.colIdx;
          const name = row[colIdx];
          if (name && typeof name === 'string' && name.trim().length > 0) {
              
              let priceTokens = row[colIdx + 1];
              let priceStr = priceTokens ? priceTokens.toString().trim() : "0";
              let price = parseFloat(priceStr.replace(/[^0-9.]/g, '')) || 0;

              let imageLink = row[colIdx + 2] || null;

              productsToInsert.push({
                  name: name.trim(),
                  base_price: price,
                  category_name: cat.name,
                  images: imageLink ? `["${escapeSql(imageLink)}"]` : '[]',
              });
          }
      }
  }

  // Insert products
  // To assign category_id, we do a subselect for each insertion, or we insert them one by one.
  // Example: 
  // INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
  // VALUES ('Prod', 10, (SELECT id FROM categories WHERE name='Cat' LIMIT 1), ARRAY[(SELECT id FROM categories WHERE name='Cat' LIMIT 1)], '[]'::jsonb, 0, 0, false);
  
  for (const p of productsToInsert) {
      sql += `INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '${escapeSql(p.name)}', 
    ${p.base_price}, 
    (SELECT id FROM public.categories WHERE name='${escapeSql(p.category_name)}' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='${escapeSql(p.category_name)}' LIMIT 1)), 
    '${p.images}'::jsonb, 
    0, 0, false
);\n`;
  }

  fs.writeFileSync('import_data.sql', sql);
  console.log(`Successfully generated import_data.sql with ${productsToInsert.length} products.`);
}

run().catch(console.error);

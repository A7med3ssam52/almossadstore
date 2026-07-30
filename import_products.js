import { createClient } from '@supabase/supabase-js';
import xlsx from 'xlsx';

const supabaseUrl = 'https://datacenter.almossadstore.com';
const supabaseKey = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MzI1NjY4MCwiZXhwIjo0OTI4OTMwMjgwLCJyb2xlIjoiYW5vbiJ9.UQ2mfh8VhaJRJZesGURRiNSaXpQpIwgSbMhB6B2bK84';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const workbook = xlsx.readFile('list.xlsx');
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = xlsx.utils.sheet_to_json(sheet, { header: 1 });
  
  if (rows.length < 2) return console.log("Empty sheet");

  const categoriesMap = new Map();
  const mainCategories = [];
  for (let c = 0; c < rows[0].length; c += 3) {
      if (rows[0][c]) {
          mainCategories.push({ name: rows[0][c].toString().trim(), colIdx: c });
      }
  }

  console.log("Categories found:", mainCategories.map(c => c.name));

  // Ensure categories exist
  for (const cat of mainCategories) {
      const { data, error } = await supabase.from('categories').select('*').eq('name', cat.name).maybeSingle();
      if (data) {
          categoriesMap.set(cat.name, data.id);
      } else {
          console.log(`Creating category: ${cat.name}`);
          const { data: newData, error: newError } = await supabase.from('categories').insert({ name: cat.name }).select().single();
          if (newError) throw newError;
          categoriesMap.set(cat.name, newData.id);
      }
  }

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
                  stock_quantity: 0,
                  category_id: categoriesMap.get(cat.name),
                  category_ids: [categoriesMap.get(cat.name)],
                  images: imageLink ? [imageLink] : [],
                  is_featured: false,
                  discount: 0
              });
          }
      }
  }

  console.log(`Found ${productsToInsert.length} products to insert.`);
  
  const chunkSize = 100;
  for (let i = 0; i < productsToInsert.length; i += chunkSize) {
      const chunk = productsToInsert.slice(i, i + chunkSize);
      const { error } = await supabase.from('products').insert(chunk);
      if (error) {
          console.error("Error inserting chunk", i, error);
      } else {
          console.log(`Inserted chunk ${i} to ${i + chunk.length}`);
      }
  }
  
  console.log("Import complete!");
}

run().catch(console.error);

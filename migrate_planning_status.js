const fs = require('fs');
const { execSync } = require('child_process');

const content = fs.readFileSync('PLANNING_STATUS.md', 'utf-8');
const lines = content.split('\n');

let inPublishedSection = false;
let seriesCategory = '';

for (const line of lines) {
    if (line.startsWith('### ')) {
        seriesCategory = line.replace('### ', '').trim();
    }
    
    if (line.startsWith('## 公開済み')) {
        inPublishedSection = true;
    }
    
    if (inPublishedSection && line.startsWith('| [')) {
        // Parse markdown table row
        // Example: | [name.md](agents/structure/name.md) | Title | Format | Date | Links |
        const parts = line.split('|').map(s => s.trim()).filter(s => s !== '');
        
        if (parts.length >= 4) {
            const structureMatch = parts[0].match(/\[(.*?)\]\((.*?)\)/);
            if (!structureMatch) continue;
            
            const filename = structureMatch[1];
            const filepath = structureMatch[2];
            const title = parts[1];
            
            // Try to find the date (it might be in different columns depending on the table)
            let date = '';
            for (const part of parts) {
                if (part.match(/202\d-\d{2}-\d{2}/)) {
                    date = part;
                    break;
                }
            }
            
            // Extract slug from filename (e.g., observer-pattern-series-structure.md -> observer-pattern)
            let slug = filename.replace('-series-structure.md', '').replace('.md', '');
            
            console.log(`Migrating: ${title} (${slug})`);
            
            const knowledge = {
                facts: [
                    `Title: ${title}`,
                    `Structure File: ${filepath}`,
                    `Publication Date: ${date || 'Unknown'}`,
                    `Category: ${seriesCategory}`
                ],
                inferences: [],
                keywords: [
                    "status:published",
                    "planning-status",
                    slug,
                    ...(seriesCategory ? [seriesCategory] : [])
                ],
                confidence_score: 100,
                summary: `Published article series: ${title}.`
            };
            
            try {
                // Escape single quotes in JSON string for bash
                const jsonStr = JSON.stringify(knowledge).replace(/'/g, "'\\''");
                execSync(`node ~/.agents/skills/semantic-knowledge-repository/scripts/save_knowledge.cjs "series-status-${slug}" '${jsonStr}'`);
            } catch (e) {
                console.error(`Failed to save ${slug}: ${e.message}`);
            }
        }
    }
}
console.log('Migration complete.');

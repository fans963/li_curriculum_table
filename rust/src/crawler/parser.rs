use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::{Campus, CourseRow, KbtableWeekHint, TimeSlot, TimetableRecord, ClassroomSchedule, OccupiedSlot};
use regex::Regex;
use scraper::{Html, Selector};
use std::collections::HashMap;
use std::sync::LazyLock;

static SLOT_REG: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"星期([一二三四五六日天])\((\d{2})-(\d{2})小节\)").unwrap());

static CELL_ENTRY_REG: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"([^\r\n]+?)\s*([0-9]{1,2}(?:\s*-\s*[0-9]{1,2})?(?:\s*,\s*[0-9]{1,2}(?:\s*-\s*[0-9]{1,2})?)*)\s*\(周\)").unwrap()
});

static BULK_WEEK_REG: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"\((\d+(?:\s*-\s*\d+)?(?:\s*,\s*\d+(?:\s*-\s*\d+)?)*)周\)").unwrap()
});


static WEEK_RANGE_REG: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(\d{1,2})").unwrap()
});

static NOBR_SELECTOR: LazyLock<Selector> = LazyLock::new(|| Selector::parse("nobr").unwrap());
static KB_CONTENT_SELECTOR: LazyLock<Selector> = LazyLock::new(|| Selector::parse("div.kbcontent1").unwrap());

pub fn parse_and_process_timetable(html_content: &str) -> CrawlerResult<TimetableRecord> {
    let document = Html::parse_document(html_content);

    // 1. Parse raw rows and headers from #dataList
    let (headers, raw_rows) = parse_data_list(&document)?;

    // 2. Parse week hints from #kbtable
    let week_hints = parse_kbtable_week_hints(&document)?;

    // 3. Merge hints into rows
    let processed_rows = merge_week_hints_into_rows(raw_rows, week_hints);

    let login_likely_success = html_content.contains("理论课表") || !processed_rows.is_empty();

    Ok(TimetableRecord {
        headers,
        rows: processed_rows,
        login_likely_success,
    })
}

fn parse_data_list(document: &Html) -> CrawlerResult<(Vec<String>, Vec<CourseRow>)> {
    let table_selector =
        Selector::parse("table#dataList").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let table = match document.select(&table_selector).next() {
        Some(t) => t,
        None => return Ok((vec![], vec![])),
    };

    let th_selector = Selector::parse("th").unwrap();
    let tr_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();

    let headers: Vec<String> = table
        .select(&th_selector)
        .map(|th| th.text().collect::<String>().trim().to_string())
        .collect();

    let mut rows = vec![];
    for tr in table.select(&tr_selector).skip(1) {
        let cols: Vec<String> = tr
            .select(&td_selector)
            .map(|td| td.text().collect::<String>().trim().to_string())
            .collect();

        if cols.len() >= 10 {
            rows.push(CourseRow {
                course_id: cols[1].clone(),
                order: cols[2].clone(),
                course_name: cols[3].clone(),
                teacher: cols[4].clone(),
                time_text: cols[5].clone(),
                credit: cols[6].clone(),
                location: cols[7].clone(),
                course_type: cols[8].clone(),
                stage: cols[9].clone(),
                slots: vec![], // Will be filled later
            });
        }
    }
    Ok((headers, rows))
}

fn parse_kbtable_week_hints(document: &Html) -> CrawlerResult<Vec<KbtableWeekHint>> {
    let table_selector =
        Selector::parse("table#kbtable").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let table = match document.select(&table_selector).next() {
        Some(t) => t,
        None => return Ok(vec![]),
    };

    let tr_selector = Selector::parse("tr").unwrap();
    let th_selector = Selector::parse("th").unwrap();
    let td_selector = Selector::parse("td").unwrap();
    let kb_content_selector = Selector::parse("div.kbcontent1").unwrap();

    let mut hints = vec![];
    for tr in table.select(&tr_selector).skip(1) {
        let row_header = tr
            .select(&th_selector)
            .next()
            .map(|th| th.text().collect::<String>())
            .unwrap_or_default();
        let section_range = section_range_from_row_header(&row_header);
        if section_range.is_none() {
            continue;
        }
        let (start_section, end_section) = section_range.unwrap();

        for (i, td) in tr.select(&td_selector).enumerate().take(7) {
            let weekday = (i + 1) as u32; // 1=Mon, ..., 7=Sun
            if let Some(div) = td.select(&kb_content_selector).next() {
                let cell_html = div.inner_html();
                let cell_text = normalize_cell_text(&cell_html);

                for cap in CELL_ENTRY_REG.captures_iter(&cell_text) {
                    let course_name = cap.get(1).map(|m| m.as_str().trim()).unwrap_or_default();
                    let week_body = cap
                        .get(2)
                        .map(|m| m.as_str().replace(' ', ""))
                        .unwrap_or_default();

                    if !course_name.is_empty() && !week_body.is_empty() {
                        hints.push(KbtableWeekHint {
                            course_name: course_name.to_string(),
                            weekday,
                            start_section,
                            end_section,
                            week_text: format!("{}(周)", week_body),
                        });
                    }
                }
            }
        }
    }
    Ok(hints)
}

fn merge_week_hints_into_rows(rows: Vec<CourseRow>, hints: Vec<KbtableWeekHint>) -> Vec<CourseRow> {
    let mut processed_rows = rows;
    for row in processed_rows.iter_mut() {
        let raw_slots = parse_course_time_slots(&row.time_text);
        if raw_slots.is_empty() {
            continue;
        }

        let slot_texts: Vec<String> = SLOT_REG
            .find_iter(&row.time_text)
            .map(|m| m.as_str().to_string())
            .collect();

        if slot_texts.len() != raw_slots.len() {
            continue;
        }

        // Logic from Dart: Group hints and slots by (weekday, session_start)
        let mut hint_groups: HashMap<String, Vec<&KbtableWeekHint>> = HashMap::new();
        for hint in hints.iter().filter(|h| h.course_name == row.course_name) {
            let key = format!(
                "{}|{}",
                hint.weekday,
                get_large_session_start(hint.start_section)
            );
            hint_groups.entry(key).or_default().push(hint);
        }

        let mut slot_groups: HashMap<String, Vec<usize>> = HashMap::new();
        for (idx, slot) in raw_slots.iter().enumerate() {
            let key = format!(
                "{}|{}",
                slot.weekday,
                get_large_session_start(slot.start_section)
            );
            slot_groups.entry(key).or_default().push(idx);
        }

        let mut final_matched_hints: Vec<Vec<String>> = vec![vec![]; raw_slots.len()];

        for (key, slot_indices) in slot_groups {
            let g_hints = hint_groups.get(&key);
            if let Some(g_hints) = g_hints {
                if slot_indices.len() == g_hints.len() && slot_indices.len() > 1 {
                    for (j, &idx) in slot_indices.iter().enumerate() {
                        final_matched_hints[idx] = vec![g_hints[j].week_text.clone()];
                    }
                } else {
                    for &idx in &slot_indices {
                        let slot = &raw_slots[idx];
                        for hint in g_hints {
                            if hint.start_section <= slot.end_section
                                && hint.end_section >= slot.start_section
                            {
                                if !final_matched_hints[idx].contains(&hint.week_text) {
                                    final_matched_hints[idx].push(hint.week_text.clone());
                                }
                            }
                        }
                    }
                }
            }
        }

        let mut merged_parts = vec![];
        let mut structured_slots = vec![];

        for i in 0..raw_slots.len() {
            let matched = &final_matched_hints[i];
            let raw_slot = &raw_slots[i];
            
            if matched.is_empty() {
                merged_parts.push(slot_texts[i].clone());
                // If no week hint, use an empty week text or try to parse from raw text if possible
                // (Usually raw rows have their own week info sometimes? 
                // In this app, week hints from #kbtable are primary)
                structured_slots.push(TimeSlot {
                    weekday: raw_slot.weekday,
                    start_section: raw_slot.start_section,
                    end_section: raw_slot.end_section,
                    start_week: 0,
                    end_week: 0,
                    week_text: String::new(),
                });
            } else {
                for week_text in matched {
                    merged_parts.push(format!("{} {}", week_text, slot_texts[i]));
                    
                    let (sw, ew) = parse_week_range(week_text);
                    structured_slots.push(TimeSlot {
                        weekday: raw_slot.weekday,
                        start_section: raw_slot.start_section,
                        end_section: raw_slot.end_section,
                        start_week: sw,
                        end_week: ew,
                        week_text: week_text.clone(),
                    });
                }
            }
        }
        row.time_text = merged_parts.join("");
        row.slots = structured_slots;
    }
    processed_rows
}

struct RawParsedSlot {
    weekday: u32,
    start_section: u32,
    end_section: u32,
}

fn parse_course_time_slots(time_text: &str) -> Vec<RawParsedSlot> {
    let mut result = vec![];
    for cap in SLOT_REG.captures_iter(time_text) {
        let weekday = chinese_to_weekday(cap.get(1).unwrap().as_str());
        let start = cap.get(2).unwrap().as_str().parse::<u32>().unwrap_or(0);
        let end = cap.get(3).unwrap().as_str().parse::<u32>().unwrap_or(0);
        if weekday > 0 && start > 0 && end > 0 {
            result.push(RawParsedSlot {
                weekday,
                start_section: start,
                end_section: end,
            });
        }
    }
    result
}

fn parse_week_range(week_text: &str) -> (u32, u32) {
    let nums: Vec<u32> = WEEK_RANGE_REG.find_iter(week_text)
        .filter_map(|m| m.as_str().parse::<u32>().ok())
        .collect();
    
    if nums.is_empty() {
        (0, 0)
    } else if nums.len() == 1 {
        (nums[0], nums[0])
    } else {
        // Pick first and last as range
        (*nums.first().unwrap(), *nums.last().unwrap())
    }
}

fn chinese_to_weekday(c: &str) -> u32 {
    match c {
        "一" => 1,
        "二" => 2,
        "三" => 3,
        "四" => 4,
        "五" => 5,
        "六" => 6,
        "日" | "天" => 7,
        _ => 0,
    }
}

fn section_range_from_row_header(text: &str) -> Option<(u32, u32)> {
    let normalized = text.replace(' ', "");
    if normalized.contains("第一大节") {
        Some((1, 3))
    } else if normalized.contains("第二大节") {
        Some((4, 5))
    } else if normalized.contains("第三大节") {
        Some((6, 7))
    } else if normalized.contains("第四大节") {
        Some((8, 10))
    } else if normalized.contains("第五大节") {
        Some((11, 13))
    } else if normalized.contains("中午") {
        Some((14, 14))
    } else {
        None
    }
}

fn get_large_session_start(section: u32) -> u32 {
    if (1..=3).contains(&section) {
        1
    } else if (4..=5).contains(&section) {
        4
    } else if (6..=7).contains(&section) {
        6
    } else if (8..=10).contains(&section) {
        8
    } else if (11..=13).contains(&section) {
        11
    } else if section == 14 {
        14
    } else {
        section
    }
}

fn normalize_cell_text(html: &str) -> String {
    let text = html
        .replace("<br>", "\n")
        .replace("<br/>", "\n")
        .replace("<br />", "\n")
        .replace("&nbsp;", " ");

    // Simple tag stripping
    let re = Regex::new(r"<[^>]*>").unwrap();
    let stripped = re.replace_all(&text, "");

    stripped
        .replace('\r', "\n")
        .replace("----------------------", "\n")
        .replace("---------------------", "\n")
        .replace("\n\n", "\n")
        .trim()
        .to_string()
}

pub fn parse_classroom_availability(html: &str, target_weekday: u32) -> CrawlerResult<HashMap<String, bool>> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("table#kbtable").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    
    let table = match document.select(&table_selector).next() {
        Some(t) => t,
        None => return Err(CrawlerError::Parse("Table #kbtable not found".to_string())),
    };

    let tr_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();

    let mut map = HashMap::new();

    // Skip header rows
    for tr in table.select(&tr_selector).skip(2) {
        let tds: Vec<_> = tr.select(&td_selector).collect();
        if tds.len() < 8 {
            continue;
        }

        // First column is classroom name (wrapped in <nobr>)
        let classroom_name = tds[0]
            .select(&NOBR_SELECTOR)
            .next()
            .map(|n| n.text().collect::<String>().trim().to_string())
            .unwrap_or_default();

        if classroom_name.is_empty() {
            continue;
        }

        // Target weekday column (1-7)
        let target_td = &tds[target_weekday as usize];
        
        // If it contains div.kbcontent1, it's occupied.
        let is_occupied = target_td.select(&KB_CONTENT_SELECTOR).next().is_some();
        map.insert(classroom_name, !is_occupied);
    }

    Ok(map)
}

pub fn parse_building_schedule(html: &str) -> CrawlerResult<Vec<ClassroomSchedule>> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("table#kbtable").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    
    let table = match document.select(&table_selector).next() {
        Some(t) => t,
        None => return Err(CrawlerError::Parse("Table #kbtable not found".to_string())),
    };

    let tr_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();

    let mut schedules = Vec::new();

    // Skip header rows (usually 2 rows)
    for tr in table.select(&tr_selector).skip(2) {
        let tds: Vec<_> = tr.select(&td_selector).collect();
        if tds.len() < 36 { // 1 (name) + 35 (7 days * 5 slots)
            continue;
        }

        let classroom_name = tds[0]
            .select(&NOBR_SELECTOR)
            .next()
            .map(|n| n.text().collect::<String>().trim().to_string())
            .unwrap_or_default();

        if classroom_name.is_empty() {
            continue;
        }

        let mut occupied_slots = Vec::new();

        for day_idx in 0..7 {
            let weekday = (day_idx + 1) as u32;
            for slot_idx in 0..5 {
                let cell_idx = 1 + day_idx * 5 + slot_idx;
                let target_td = &tds[cell_idx];
                
                for div in target_td.select(&KB_CONTENT_SELECTOR) {
                    let cell_html = div.inner_html();
                    let cell_text = normalize_cell_text(&cell_html);

                    // For building schedule, weeks are typically in (1-16周) format
                    for cap in BULK_WEEK_REG.captures_iter(&cell_text) {
                        let week_body = cap
                            .get(1)
                            .map(|m| m.as_str().replace(' ', ""))
                            .unwrap_or_default();

                        if !week_body.is_empty() {
                            for part in week_body.split(',') {
                                let (sw, ew) = parse_week_range(part);
                                if sw > 0 && ew > 0 {
                                    occupied_slots.push(OccupiedSlot {
                                        start_week: sw,
                                        end_week: ew,
                                        weekday,
                                        slot_index: slot_idx as u32,
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }


        schedules.push(ClassroomSchedule {
            classroom_name,
            occupied_slots,
        });
    }

    Ok(schedules)
}

pub fn parse_campuses(html: &str) -> CrawlerResult<Vec<Campus>> {
    let document = Html::parse_document(html);
    let select_selector = Selector::parse("select[name='xqid']").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let option_selector = Selector::parse("option").unwrap();

    let select = match document.select(&select_selector).next() {
        Some(s) => s,
        None => return Err(CrawlerError::Parse("Select[name='xqid'] not found".to_string())),
    };

    let mut campuses = vec![];
    for option in select.select(&option_selector) {
        let id = option.value().attr("value").unwrap_or_default().to_string();
        let name = option.text().collect::<String>().trim().to_string();
        if !id.is_empty() {
            campuses.push(Campus { id, name });
        }
    }

    Ok(campuses)
}

use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::{Campus, ClassroomSchedule, OccupiedSlot};
use rayon::prelude::*;
use regex_lite::Regex;
use scraper::{Html, Selector};
use std::collections::HashMap;
use std::sync::LazyLock;

use super::timetable::{normalize_cell_text, parse_week_range};

static BULK_WEEK_REG: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"\((\d+(?:\s*-\s*\d+)?(?:\s*,\s*\d+(?:\s*-\s*\d+)?)*)周\)").unwrap()
});

static NOBR_SELECTOR: LazyLock<Selector> = LazyLock::new(|| Selector::parse("nobr").unwrap());
static KB_CONTENT_SELECTOR: LazyLock<Selector> =
    LazyLock::new(|| Selector::parse("div.kbcontent1").unwrap());

pub fn parse_classroom_availability(
    html: &str,
    target_weekday: u32,
) -> CrawlerResult<HashMap<String, bool>> {
    let document = Html::parse_document(html);
    let table_selector =
        Selector::parse("table#kbtable").map_err(|e| CrawlerError::Parse(e.to_string()))?;

    let table = match document.select(&table_selector).next() {
        Some(t) => t,
        None => return Err(CrawlerError::Parse("Table #kbtable not found".to_string())),
    };

    let tr_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();

    // Sequential: extract (name, is_occupied) pairs
    let pairs: Vec<(String, bool)> = table
        .select(&tr_selector)
        .skip(2)
        .filter_map(|tr| {
            let tds: Vec<_> = tr.select(&td_selector).collect();
            if tds.len() < 8 {
                return None;
            }
            let classroom_name = tds[0]
                .select(&NOBR_SELECTOR)
                .next()
                .map(|n| n.text().collect::<String>().trim().to_string())
                .unwrap_or_default();
            if classroom_name.is_empty() {
                return None;
            }
            let target_td = &tds[target_weekday as usize];
            let is_occupied = target_td.select(&KB_CONTENT_SELECTOR).next().is_some();
            Some((classroom_name, !is_occupied))
        })
        .collect();

    Ok(pairs.into_iter().collect())
}

/// Parse a single classroom row's 35 cells into occupied slots.
fn parse_classroom_row(classroom_name: String, cell_htmls: Vec<String>) -> ClassroomSchedule {
    let mut occupied_slots = Vec::new();

    for day_idx in 0..7u32 {
        let weekday = day_idx + 1;
        for slot_idx in 0..5u32 {
            let cell_idx = (day_idx * 5 + slot_idx) as usize;
            let cell_text = normalize_cell_text(&cell_htmls[cell_idx]);

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
                                slot_index: slot_idx,
                            });
                        }
                    }
                }
            }
        }
    }

    ClassroomSchedule {
        classroom_name,
        occupied_slots,
    }
}

pub fn parse_building_schedule(html: &str) -> CrawlerResult<Vec<ClassroomSchedule>> {
    let document = Html::parse_document(html);
    let table_selector =
        Selector::parse("table#kbtable").map_err(|e| CrawlerError::Parse(e.to_string()))?;

    let table = match document.select(&table_selector).next() {
        Some(t) => t,
        None => return Err(CrawlerError::Parse("Table #kbtable not found".to_string())),
    };

    let tr_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();

    // Sequential: extract classroom names + cell HTMLs (ElementRef is !Send)
    let rows_data: Vec<(String, Vec<String>)> = table
        .select(&tr_selector)
        .skip(2)
        .filter_map(|tr| {
            let tds: Vec<_> = tr.select(&td_selector).collect();
            if tds.len() < 36 {
                return None;
            }
            let classroom_name = tds[0]
                .select(&NOBR_SELECTOR)
                .next()
                .map(|n| n.text().collect::<String>().trim().to_string())
                .unwrap_or_default();
            if classroom_name.is_empty() {
                return None;
            }
            // Extract inner_html from the 35 schedule cells
            let cell_htmls: Vec<String> = (1..36).map(|i| tds[i].inner_html()).collect();
            Some((classroom_name, cell_htmls))
        })
        .collect();

    // Parallel: parse each classroom's schedule independently
    let schedules: Vec<ClassroomSchedule> = rows_data
        .into_par_iter()
        .map(|(name, htmls)| parse_classroom_row(name, htmls))
        .collect();

    Ok(schedules)
}

pub fn parse_campuses(html: &str) -> CrawlerResult<crate::crawler::model::CampusPageData> {
    let document = Html::parse_document(html);
    let select_selector =
        Selector::parse("select[name='xqid']").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let option_selector = Selector::parse("option").unwrap();

    let select = match document.select(&select_selector).next() {
        Some(s) => s,
        None => {
            return Err(CrawlerError::Parse(
                "Select[name='xqid'] not found".to_string(),
            ))
        }
    };

    let mut campuses = vec![];
    for option in select.select(&option_selector) {
        let id = option.value().attr("value").unwrap_or_default().to_string();
        let name = option.text().collect::<String>().trim().to_string();
        if !id.is_empty() {
            campuses.push(Campus { id, name });
        }
    }

    let current_term = parse_selected_term(&document);

    Ok(crate::crawler::model::CampusPageData {
        campuses,
        current_term,
    })
}

fn parse_selected_term(document: &Html) -> String {
    let term_selector = match Selector::parse("select[name='xnxqh'] option[selected]") {
        Ok(s) => s,
        Err(_) => return String::new(),
    };

    document
        .select(&term_selector)
        .next()
        .and_then(|opt| opt.value().attr("value"))
        .unwrap_or_default()
        .to_string()
}

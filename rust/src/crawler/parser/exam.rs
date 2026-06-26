use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::{Exam, ExamRecord};
use rayon::prelude::*;
use scraper::{Html, Selector};

pub fn parse_exam_query_term(html: &str) -> Option<String> {
    let document = Html::parse_document(html);

    let selected_sel = match Selector::parse("select[name='xnxqid'] option[selected]") {
        Ok(s) => s,
        Err(_) => return None,
    };
    if let Some(opt) = document.select(&selected_sel).next() {
        let val = opt.value().attr("value").unwrap_or_default().to_string();
        if !val.is_empty() {
            log::info!("parse_exam_query_term: found selected term='{}'", val);
            return Some(val);
        }
    }

    let option_sel = match Selector::parse("select[name='xnxqid'] option") {
        Ok(s) => s,
        Err(_) => return None,
    };
    for opt in document.select(&option_sel) {
        let val = opt.value().attr("value").unwrap_or_default().to_string();
        if !val.is_empty() {
            log::info!("parse_exam_query_term: using first option term='{}'", val);
            return Some(val);
        }
    }

    log::warn!("parse_exam_query_term: no term found");
    None
}

pub fn parse_exams(html: &str) -> CrawlerResult<ExamRecord> {
    log::info!("parse_exams: HTML length={}", html.len());

    let document = Html::parse_document(html);
    let table_selector =
        Selector::parse("table#dataList").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let row_selector = Selector::parse("tr").map_err(|e| CrawlerError::Parse(e.to_string()))?;

    let Some(table) = document.select(&table_selector).next() else {
        log::warn!("parse_exams: table#dataList NOT found in HTML");
        return Ok(ExamRecord { exams: vec![] });
    };

    // Sequential: extract owned text from DOM
    let td_selector = Selector::parse("td").unwrap();
    let rows_data: Vec<Vec<String>> = table
        .select(&row_selector)
        .skip(1)
        .filter_map(|row| {
            let cells: Vec<String> = row
                .select(&td_selector)
                .map(|td| td.text().collect::<String>().trim().to_string())
                .collect();
            if cells.len() < 7 { None } else { Some(cells) }
        })
        .collect();

    log::info!("parse_exams: {} data rows", rows_data.len());

    // Parallel: parse into Exam entities
    let exams: Vec<Exam> = rows_data
        .into_par_iter()
        .filter_map(|c| {
            let course_name = c[3].clone();
            if course_name.is_empty() {
                return None;
            }
            Some(Exam {
                session: c[1].clone(),
                course_code: c[2].clone(),
                course_name,
                exam_time: c[4].clone(),
                location: c[5].clone(),
                seat_number: c[6].clone(),
            })
        })
        .collect();

    log::info!("parse_exams: Returning {} exams", exams.len());
    Ok(ExamRecord { exams })
}

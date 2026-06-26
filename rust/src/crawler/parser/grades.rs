use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::{Grade, GradeRecord, LevelExamScore, LevelExamScoreRecord};
use rayon::prelude::*;
use scraper::{Html, Selector};
use std::collections::HashMap;

/// Extract text from each cell of a row into owned Strings.
fn extract_cell_texts(row: &scraper::ElementRef, min_cells: usize) -> Option<Vec<String>> {
    let cells: Vec<String> = row
        .select(&Selector::parse("td").unwrap())
        .map(|td| td.text().collect::<String>().trim().to_string())
        .collect();
    if cells.len() < min_cells {
        None
    } else {
        Some(cells)
    }
}

pub fn parse_grades(html: &str) -> CrawlerResult<GradeRecord> {
    let document = Html::parse_document(html);
    let table_selector =
        Selector::parse("table#dataList").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let row_selector = Selector::parse("tr").map_err(|e| CrawlerError::Parse(e.to_string()))?;

    let Some(table) = document.select(&table_selector).next() else {
        log::warn!("Parser: table#dataList not found in grades HTML.");
        return Ok(GradeRecord { grades: vec![] });
    };

    // Sequential: extract owned text data from DOM (ElementRef is !Send)
    let rows_data: Vec<Vec<String>> = table
        .select(&row_selector)
        .skip(1)
        .filter_map(|row| extract_cell_texts(&row, 11))
        .collect();

    // Parallel: parse structured data from owned strings
    let grades: Vec<Grade> = rows_data
        .into_par_iter()
        .filter_map(|c| {
            let course_name = c[3].trim().to_string();
            if course_name.is_empty() {
                return None;
            }
            Some(Grade {
                term: c[1].clone(),
                course_code: c[2].clone(),
                course_name,
                score: c[4].clone(),
                score_mark: c[5].clone(),
                credits: c[6].parse::<f64>().unwrap_or(0.0),
                total_hours: c[7].parse::<u32>().unwrap_or(0),
                assessment_method: c[8].clone(),
                course_attribute: c[9].clone(),
                course_nature: c[10].clone(),
            })
        })
        .collect();

    Ok(GradeRecord { grades })
}

/// Parse level exam scores (等级考试成绩). Only the highest total score per course is kept.
pub fn parse_level_exam_scores(html: &str) -> CrawlerResult<LevelExamScoreRecord> {
    let document = Html::parse_document(html);
    let table_selector =
        Selector::parse("table#dataList").map_err(|e| CrawlerError::Parse(e.to_string()))?;
    let row_selector = Selector::parse("tr").map_err(|e| CrawlerError::Parse(e.to_string()))?;

    let Some(table) = document.select(&table_selector).next() else {
        log::warn!("parse_level_exam_scores: table#dataList not found");
        return Ok(LevelExamScoreRecord { scores: vec![] });
    };

    // Sequential: extract owned text (skip 2 header rows)
    let rows_data: Vec<Vec<String>> = table
        .select(&row_selector)
        .skip(2)
        .filter_map(|row| extract_cell_texts(&row, 9))
        .collect();

    // Parallel: parse into LevelExamScore
    let parsed: Vec<LevelExamScore> = rows_data
        .into_par_iter()
        .filter_map(|c| {
            let course_name = c[1].trim().to_string();
            if course_name.is_empty() {
                return None;
            }
            Some(LevelExamScore {
                course_name,
                written_score: c[2].clone(),
                practical_score: c[3].clone(),
                total_score: c[4].clone(),
                written_grade: c[5].clone(),
                practical_grade: c[6].clone(),
                total_grade: c[7].clone(),
                exam_date: c[8].clone(),
            })
        })
        .collect();

    // Sequential merge: keep highest total score per course
    let mut best_by_course: HashMap<String, LevelExamScore> = HashMap::new();
    for score in parsed {
        let new_total = score.total_score.parse::<f64>().unwrap_or(0.0);
        let should_replace = match best_by_course.get(&score.course_name) {
            Some(existing) => {
                let old_total = existing.total_score.parse::<f64>().unwrap_or(0.0);
                new_total > old_total
            }
            None => true,
        };
        if should_replace {
            best_by_course.insert(score.course_name.clone(), score);
        }
    }

    let scores: Vec<LevelExamScore> = best_by_course.into_values().collect();
    log::info!("parse_level_exam_scores: {} unique courses", scores.len());
    Ok(LevelExamScoreRecord { scores })
}

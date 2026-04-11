#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_parse_grades_real_data() {
        let html =
            fs::read_to_string("/home/fan/workspace/flutter/curriculum_table/cjcx_list").unwrap();
        let record = parse_grades(&html).unwrap();

        assert!(!record.grades.is_empty());
        println!("Parsed {} grades", record.grades.len());

        // Verify first row based on cjcx_list content
        let first = &record.grades[0];
        assert_eq!(first.course_name, "大学英语（Ⅰ）");
        assert_eq!(first.score, "73");
        assert_eq!(first.credits, 3.5);

        // Verify a row with textual grades (e.g. Row 10 - 形势与政策)
        let row_with_text = record
            .grades
            .iter()
            .find(|g| g.course_name.contains("形势与政策"))
            .expect("Should find 形势与政策");
        println!(
            "Found: {} with score {}",
            row_with_text.course_name, row_with_text.score
        );

        // Let's check the mapping logic indirectly if needed, but here we just test parsing
    }
}

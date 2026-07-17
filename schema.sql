-- Schema for NovaBank Credit Risk Analysis

CREATE TABLE Borrowers (
    borrower_id INT PRIMARY KEY,
    name VARCHAR(100),
    country VARCHAR(50),
    home_ownership VARCHAR(50),
    annual_income DECIMAL(18,2),
    dti DECIMAL(5,2),
    lti DECIMAL(5,2),
    credit_score INT
);

CREATE TABLE Loans (
    loan_id INT PRIMARY KEY,
    borrower_id INT,
    loan_amount DECIMAL(18,2),
    loan_grade VARCHAR(10),
    interest_rate DECIMAL(5,2),
    term_months INT,
    default_flag BIT,
    FOREIGN KEY (borrower_id) REFERENCES Borrowers(borrower_id)
);

CREATE OR REPLACE VIEW Global_Enterprise_Health_Monitor AS
WITH DeptPerformance AS (
    SELECT 
        d.dept_name,
        COUNT(e.emp_id) AS staff_count,
        SUM(e.salary) AS payroll_cost,
        (SELECT COUNT(*) FROM Orders o JOIN Employees e2 ON o.cust_id = e2.emp_id WHERE e2.dept_id = d.dept_id) AS internal_orders
    FROM Departments d
    LEFT JOIN Employees e ON d.dept_id = e.dept_id
    GROUP BY d.dept_id, d.dept_name
),
SalesMetrics AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-Q%v') AS fiscal_period,
        SUM(total_amount) AS gross_revenue,
        COUNT(order_id) AS order_volume,
        AVG(total_amount) AS ticket_size
    FROM Orders
    GROUP BY fiscal_period
),
InventoryRisk AS (
    SELECT 
        SUM(CASE WHEN stock_quantity = 0 THEN 1 ELSE 0 END) AS out_of_stock_items,
        SUM(price * stock_quantity) AS total_asset_value
    FROM Products
)
SELECT 
    sm.fiscal_period,
    FORMAT(sm.gross_revenue, 2) AS total_revenue,
    sm.order_volume,
    FORMAT(dp.payroll_cost, 2) AS total_payroll,
    ROUND((sm.gross_revenue / dp.payroll_cost), 2) AS revenue_per_payroll_dollar,
    ir.out_of_stock_items,
    FORMAT(ir.total_asset_value, 2) AS warehouse_valuation,
    CASE 
        WHEN sm.gross_revenue > dp.payroll_cost * 3 THEN 'OPTIMAL_GROWTH'
        WHEN sm.gross_revenue > dp.payroll_cost THEN 'STABLE_OPERATIONS'
        ELSE 'FINANCIAL_RESTRUCTURING_REQUIRED'
    END AS enterprise_status
FROM SalesMetrics sm
CROSS JOIN (SELECT SUM(payroll_cost) as payroll_cost FROM DeptPerformance) dp
CROSS JOIN InventoryRisk ir
ORDER BY sm.fiscal_period DESC;

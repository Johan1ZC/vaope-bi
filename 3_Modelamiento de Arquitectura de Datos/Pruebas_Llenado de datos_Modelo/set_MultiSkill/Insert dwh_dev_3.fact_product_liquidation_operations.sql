INSERT INTO dwh_dev_3.fact_product_liquidation_operations (
  ProductLiquidationOperationID,
  ProductLiquidationID,
  EventID,
  TypeOperation,
  CodeSecondary,
  OperationName,
  Amount,
  UserID,
  Description,
  RequiresApproval,
  ChargedTo,
  PaymentMethod,
  CreatedAt,
  UpdatedAt,
  Approved,
  ApprovedBy,
  ApprovedAt
)
SELECT
  a.id,
  a.product_liquidation_id,
  a.event_id,
  a.type_operation,
  b.code_secondary,
  b.name,
  a.amount,
  a.user_id,
  a.description,
  a.requires_approval,
  a.charged_to,
  a.payment_method,
  a.created_at,
  a.updated_at,
  a.approved,
  a.approved_by,
  a.approved_at
FROM vaope_qa4.product_liquidation_operations a
left join vaope_qa4.var_masters b 
on a.type_operation = b.cod 
and b.deleted_at is null 
and b.root = 9 
and b.code_secondary IS NOT NULL
where a.deleted_at is null 
and year(a.created_at) >= 2026;
  
-- select * from fact_product_liquidation_operations
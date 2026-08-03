-- =========================================================================
-- StockRadar / Netsis-style mock commercial dataset (POSTGRESQL VERSİYONU)
-- =========================================================================

CREATE SCHEMA IF NOT EXISTS mock;

-- Eski tabloları güvenli bir şekilde uçuralım

DROP TABLE IF EXISTS mock.Sale CASCADE;


DROP TABLE IF EXISTS mock.Product CASCADE;


DROP TABLE IF EXISTS mock.ProductCategory CASCADE;


DROP TABLE IF EXISTS mock.InventoryCategory CASCADE;


DROP TABLE IF EXISTS mock.BrandCustomer CASCADE;


DROP TABLE IF EXISTS mock.Brand CASCADE;


DROP TABLE IF EXISTS mock.Customer CASCADE;

-- 1. Müşteriler

CREATE TABLE mock.Customer (CustomerId SERIAL PRIMARY KEY,
                                              ERPCustomerName VARCHAR(200) NOT NULL UNIQUE,
                                                                                    CustomerGroup VARCHAR(100) NOT NULL,
                                                                                                               CountryCode CHAR(2) NOT NULL,
                                                                                                                                   CurrencyCode CHAR(3) NOT NULL,
                                                                                                                                                        IsActive BOOLEAN NOT NULL DEFAULT TRUE);

-- 2. Markalar

CREATE TABLE mock.Brand (BrandId SERIAL PRIMARY KEY,
                                        ERPBrandCode VARCHAR(20) NOT NULL UNIQUE,
                                                                          BrandName VARCHAR(100) NOT NULL,
                                                                                                 BrandGroup VARCHAR(100),
                                                                                                            IsActive BOOLEAN NOT NULL DEFAULT TRUE);

-- 3. Marka-Müşteri İlişkisi

CREATE TABLE mock.BrandCustomer (BrandId INT NOT NULL REFERENCES mock.Brand(BrandId),
                                                                 CustomerId INT NOT NULL REFERENCES mock.Customer(CustomerId),
                                                                                                    IsPrimary BOOLEAN NOT NULL DEFAULT FALSE,
                                                                                                                                       PRIMARY KEY (BrandId,
                                                                                                                                                    CustomerId));

-- 4. Stok/Envanter Kategorileri

CREATE TABLE mock.InventoryCategory (InventoryCategoryId SERIAL PRIMARY KEY,
                                                                ERPProductGroup VARCHAR(50) NOT NULL UNIQUE,
                                                                                                     DefaultUnit VARCHAR(10) NOT NULL,
                                                                                                                             IsFinishedProduct BOOLEAN NOT NULL);

-- 5. Ürün Kategorileri

CREATE TABLE mock.ProductCategory (ProductCategoryId SERIAL PRIMARY KEY,
                                                            ERPGroupName VARCHAR(100) NOT NULL UNIQUE,
                                                                                               ProductFamily VARCHAR(50) NOT NULL,
                                                                                                                         DecorationType VARCHAR(30) NOT NULL,
                                                                                                                                                    DefaultUnit VARCHAR(10) NOT NULL DEFAULT 'Adet',
                                                                                                                                                                                             IsActive BOOLEAN NOT NULL DEFAULT TRUE);

-- 6. Ürünler (Mamuller)

CREATE TABLE mock.Product (ProductId SERIAL PRIMARY KEY,
                                            SKU VARCHAR(40) NOT NULL UNIQUE,
                                                                     ModelCode VARCHAR(40) NOT NULL,
                                                                                           ProductName VARCHAR(200) NOT NULL,
                                                                                                                    BrandId INT NOT NULL REFERENCES mock.Brand(BrandId),
                                                                                                                                                    CustomerId INT NOT NULL REFERENCES mock.Customer(CustomerId),
                                                                                                                                                                                       ProductCategoryId INT NOT NULL REFERENCES mock.ProductCategory(ProductCategoryId),
                                                                                                                                                                                                                                 ERPProductGroup VARCHAR(50) NOT NULL DEFAULT 'Mamul',
                                                                                                                                                                                                                                                                              SeasonCode VARCHAR(20) NOT NULL,
                                                                                                                                                                                                                                                                                                     ColorCode VARCHAR(30) NOT NULL,
                                                                                                                                                                                                                                                                                                                           SizeCode VARCHAR(10) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                Unit VARCHAR(10) NOT NULL DEFAULT 'Adet',
                                                                                                                                                                                                                                                                                                                                                                                  ListPrice NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                           StandardCost NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                       IsActive BOOLEAN NOT NULL DEFAULT TRUE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         CHECK (ListPrice > 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                AND StandardCost >= 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                AND StandardCost <= ListPrice));

-- 7. Satışlar (Otomatik Hesaplanan Kolonlarla Birlikte)

CREATE TABLE mock.Sale (SaleId BIGSERIAL PRIMARY KEY,
                                         OrderNo VARCHAR(40) NOT NULL,
                                                             OrderLineNo SMALLINT NOT NULL,
                                                                                  InvoiceNo VARCHAR(40),
                                                                                            SaleDate DATE NOT NULL,
                                                                                                          RequestedDate DATE NOT NULL,
                                                                                                                             ProductId INT NOT NULL REFERENCES mock.Product(ProductId),
                                                                                                                                                               BrandId INT NOT NULL REFERENCES mock.Brand(BrandId),
                                                                                                                                                                                               CustomerId INT NOT NULL REFERENCES mock.Customer(CustomerId),
                                                                                                                                                                                                                                  ProductCategoryId INT NOT NULL REFERENCES mock.ProductCategory(ProductCategoryId),
                                                                                                                                                                                                                                                                            DocumentType VARCHAR(10) NOT NULL CHECK (DocumentType IN ('SALE',
                                                                                                                                                                                                                                                                                                                                      'RETURN')), Quantity INT NOT NULL,
                                                                                                                                                                                                                                                                                                                                                               Unit VARCHAR(10) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                CurrencyCode CHAR(3) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                     UnitPrice NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                              UnitCost NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                      DiscountPct NUMERIC(5, 2) NOT NULL CHECK (DiscountPct BETWEEN 0 AND 100), SalesChannel VARCHAR(20) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         MarketCode CHAR(2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            OrderStatus VARCHAR(20) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    GrossAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitPrice) STORED,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         NetAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitPrice * (1 - DiscountPct / 100.0)) STORED,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            CostAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitCost) STORED,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                MarginAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitPrice * (1 - DiscountPct / 100.0) - Quantity * UnitCost) STORED);

-- --- SABİT VERİLERİ (SEED) ---

INSERT INTO mock.Customer (ERPCustomerName, CustomerGroup, CountryCode, CurrencyCode)
VALUES ('H&M', 'H&M Group', 'SE', 'EUR'),
       ('ITX TRADING S.A', 'Inditex', 'ES', 'EUR'),
       ('EMEA ASPIRE TRADING FZE', 'Inditex EMEA', 'AE', 'EUR'),
       ('C&A Buying GmbH & Co. KG', 'C&A', 'DE', 'EUR'),
       ('PRIMARK LIMITED', 'Primark', 'GB', 'GBP'),
       ('LPP COMPANY', 'LPP', 'PL', 'EUR'),
       ('ASDA STORES LIMITED', 'ASDA', 'GB', 'GBP');


INSERT INTO mock.Brand (ERPBrandCode, BrandName, BrandGroup)
VALUES ('H&M', 'H&M', 'H&M Group'),
       ('ZAR', 'Zara', 'Inditex'),
       ('C&A', 'C&A', 'C&A'),
       ('BER', 'Bershka', 'Inditex'),
       ('PRI', 'Primark', 'Primark'),
       ('RSV', 'Reserved', 'LPP'),
       ('STR', 'Stradivarius', 'Inditex'),
       ('GEO', 'George', 'ASDA');


INSERT INTO mock.BrandCustomer (BrandId, CustomerId, IsPrimary)
VALUES (1,1,TRUE),
       (2,2,TRUE),
       (2,3,FALSE),
       (3,4,TRUE),
       (4,2,TRUE),
       (4,3,FALSE),
       (5,5,TRUE),
       (6,6,TRUE),
       (7,2,TRUE),
       (8,7,TRUE);


INSERT INTO mock.InventoryCategory (ERPProductGroup, DefaultUnit, IsFinishedProduct)
VALUES ('Aksesuar', 'Adet', FALSE),
       ('Boyalı Kumaş', 'Kg', FALSE),
       ('Ham Kumaş', 'Kg', FALSE),
       ('İplik', 'Kg', FALSE),
       ('Mamul', 'Adet', TRUE);


INSERT INTO mock.ProductCategory (ERPGroupName, ProductFamily, DecorationType)
VALUES ('Solid Top', 'Top', 'Solid'),
       ('Solid Elbise', 'Elbise', 'Solid'),
       ('Baskılı Tshirt', 'Tshirt', 'Baskılı'),
       ('Solid Tshirt', 'Tshirt', 'Solid'),
       ('Baskılı Sweatshirt', 'Sweatshirt', 'Baskılı'),
       ('Solid Pantolon', 'Pantolon', 'Solid'),
       ('Solid Bluz', 'Bluz', 'Solid'),
       ('Solid Etek', 'Etek', 'Solid'),
       ('Solid Sweatshirt', 'Sweatshirt', 'Solid'),
       ('Solid Body', 'Body', 'Solid'),
       ('Solid Şort', 'Şort', 'Solid'),
       ('Solid Legging', 'Legging', 'Solid'),
       ('Baskılı Top', 'Top', 'Baskılı'),
       ('Baskılı Elbise', 'Elbise', 'Baskılı'),
       ('Solid Atlet', 'Atlet', 'Solid'),
       ('Solid Jogger', 'Jogger', 'Solid'),
       ('Nakışlı Top', 'Top', 'Nakışlı'),
       ('Nakışlı Sweatshirt', 'Sweatshirt', 'Nakışlı'),
       ('Solid Jacket', 'Jacket', 'Solid'),
       ('Solid Cardigan', 'Cardigan', 'Solid');

-- 1000 Adet Ürün Üretme

INSERT INTO mock.Product (SKU, ModelCode, ProductName, BrandId, CustomerId, ProductCategoryId, SeasonCode, ColorCode, SizeCode, ListPrice, StandardCost)
SELECT 'MOCK-' || b.ERPBrandCode || '-' || LPAD(g::text, 6, '0'),
       'MDL-' || b.ERPBrandCode || '-' || LPAD((((g-1)/5)+1)::text, 5, '0'),
       b.BrandName || ' ' || pc.ERPGroupName || ' ' || LPAD(g::text, 6, '0'),
       b.BrandId,
    (SELECT CustomerId
     FROM mock.BrandCustomer
     WHERE BrandId = b.BrandId
     LIMIT 1), pc.ProductCategoryId, (ARRAY['SS25',
                                            'FW25',
                                            'SS26',
                                            'FW26',
                                            'CORE',
                                            'NOS'])[((g-1) % 6) + 1], (ARRAY['SİYAH',
                                                                             'BEYAZ',
                                                                             'LACİVERT',
                                                                             'GRİ',
                                                                             'KIRMIZI',
                                                                             'YEŞİL',
                                                                             'MAVİ',
                                                                             'BEJ'])[((g-1) % 8) + 1], (ARRAY['XS',
                                                                                                              'S',
                                                                                                              'M',
                                                                                                              'L',
                                                                                                              'XL',
                                                                                                              'XXL'])[((g-1) % 6) + 1], ROUND((8.00 + ((g * 17) % 7200) / 100.0)::numeric, 2),
                                                                                                                                        ROUND(((8.00 + ((g * 17) % 7200) / 100.0) * (0.46 + ((g * 7) % 15) / 100.0))::numeric, 2)
FROM generate_series(1, 1000) AS g
JOIN mock.Brand b ON b.BrandId = ((g-1) % 8) + 1
JOIN mock.ProductCategory pc ON pc.ProductCategoryId = ((g-1) % 20) + 1;

-- 50.000 Satırlık Satış ve İade Verisi Üretme

INSERT INTO mock.Sale (OrderNo, OrderLineNo, InvoiceNo, SaleDate, RequestedDate, ProductId, BrandId, CustomerId, ProductCategoryId, DocumentType, Quantity, Unit, CurrencyCode, UnitPrice, UnitCost, DiscountPct, SalesChannel, MarketCode, OrderStatus)
SELECT 'SO-' || EXTRACT(YEAR
                        FROM (DATE '2025-01-01' + ((g * 13) % 560))) || '-' || LPAD((((g-1)/3)+1)::text, 7, '0'),
       ((g-1) % 3) + 1,
       'INV-' || EXTRACT(YEAR
                         FROM (DATE '2025-01-01' + ((g * 13) % 560))) || '-' || LPAD((((g-1)/8)+1)::text, 7, '0'),
       DATE '2025-01-01' + ((g * 13) % 560),
       DATE '2025-01-01' + ((g * 13) % 560) + (14 + (g % 45)),
       p.ProductId,
       p.BrandId,
       p.CustomerId,
       p.ProductCategoryId,
       CASE
           WHEN g % 25 = 0 THEN 'RETURN'
           ELSE 'SALE'
       END,
       CASE
           WHEN g % 25 = 0 THEN -((g * 17) % 500 + 1)
           ELSE ((g * 17) % 500 + 1)
       END,
       p.Unit,
       'EUR',
       ROUND((p.ListPrice * (0.95 + ((g * 7) % 10) / 100.0))::numeric, 2),
       p.StandardCost,
       ROUND((((g * 19) % 2501) / 100.0)::numeric, 2),
       'B2B',
       'TR',
       CASE
           WHEN g % 20 = 0 THEN 'SHIPPED'
           ELSE 'INVOICED'
       END
FROM generate_series(1, 50000) AS g
JOIN mock.Product p ON p.ProductId = ((g-1) % 1000) + 1;

-- =====================================================
-- ASİSTAN İÇİN KOLAYLAŞTIRICI SANAL TABLOLAR (VIEWS)
-- =====================================================

CREATE OR REPLACE VIEW mock.iadeler AS
SELECT *
FROM mock.Sale
WHERE DocumentType = 'RETURN';


CREATE OR REPLACE VIEW mock.net_satislar AS
SELECT *
FROM mock.Sale
WHERE DocumentType = 'SALE';

-- =========================================================================
-- StockRadar / Netsis-style mock commercial dataset (POSTGRESQL VERSİYONU)
-- =========================================================================

CREATE SCHEMA IF NOT EXISTS mock;

-- Eski tabloları güvenli bir şekilde uçuralım

DROP TABLE IF EXISTS mock.Sale CASCADE;


DROP TABLE IF EXISTS mock.Product CASCADE;


DROP TABLE IF EXISTS mock.ProductCategory CASCADE;


DROP TABLE IF EXISTS mock.InventoryCategory CASCADE;


DROP TABLE IF EXISTS mock.BrandCustomer CASCADE;


DROP TABLE IF EXISTS mock.Brand CASCADE;


DROP TABLE IF EXISTS mock.Customer CASCADE;

-- 1. Müşteriler

CREATE TABLE mock.Customer (CustomerId SERIAL PRIMARY KEY,
                                              ERPCustomerName VARCHAR(200) NOT NULL UNIQUE,
                                                                                    CustomerGroup VARCHAR(100) NOT NULL,
                                                                                                               CountryCode CHAR(2) NOT NULL,
                                                                                                                                   CurrencyCode CHAR(3) NOT NULL,
                                                                                                                                                        IsActive BOOLEAN NOT NULL DEFAULT TRUE);

-- 2. Markalar

CREATE TABLE mock.Brand (BrandId SERIAL PRIMARY KEY,
                                        ERPBrandCode VARCHAR(20) NOT NULL UNIQUE,
                                                                          BrandName VARCHAR(100) NOT NULL,
                                                                                                 BrandGroup VARCHAR(100),
                                                                                                            IsActive BOOLEAN NOT NULL DEFAULT TRUE);

-- 3. Marka-Müşteri İlişkisi

CREATE TABLE mock.BrandCustomer (BrandId INT NOT NULL REFERENCES mock.Brand(BrandId),
                                                                 CustomerId INT NOT NULL REFERENCES mock.Customer(CustomerId),
                                                                                                    IsPrimary BOOLEAN NOT NULL DEFAULT FALSE,
                                                                                                                                       PRIMARY KEY (BrandId,
                                                                                                                                                    CustomerId));

-- 4. Stok/Envanter Kategorileri

CREATE TABLE mock.InventoryCategory (InventoryCategoryId SERIAL PRIMARY KEY,
                                                                ERPProductGroup VARCHAR(50) NOT NULL UNIQUE,
                                                                                                     DefaultUnit VARCHAR(10) NOT NULL,
                                                                                                                             IsFinishedProduct BOOLEAN NOT NULL);

-- 5. Ürün Kategorileri

CREATE TABLE mock.ProductCategory (ProductCategoryId SERIAL PRIMARY KEY,
                                                            ERPGroupName VARCHAR(100) NOT NULL UNIQUE,
                                                                                               ProductFamily VARCHAR(50) NOT NULL,
                                                                                                                         DecorationType VARCHAR(30) NOT NULL,
                                                                                                                                                    DefaultUnit VARCHAR(10) NOT NULL DEFAULT 'Adet',
                                                                                                                                                                                             IsActive BOOLEAN NOT NULL DEFAULT TRUE);

-- 6. Ürünler (Mamuller)

CREATE TABLE mock.Product (ProductId SERIAL PRIMARY KEY,
                                            SKU VARCHAR(40) NOT NULL UNIQUE,
                                                                     ModelCode VARCHAR(40) NOT NULL,
                                                                                           ProductName VARCHAR(200) NOT NULL,
                                                                                                                    BrandId INT NOT NULL REFERENCES mock.Brand(BrandId),
                                                                                                                                                    CustomerId INT NOT NULL REFERENCES mock.Customer(CustomerId),
                                                                                                                                                                                       ProductCategoryId INT NOT NULL REFERENCES mock.ProductCategory(ProductCategoryId),
                                                                                                                                                                                                                                 ERPProductGroup VARCHAR(50) NOT NULL DEFAULT 'Mamul',
                                                                                                                                                                                                                                                                              SeasonCode VARCHAR(20) NOT NULL,
                                                                                                                                                                                                                                                                                                     ColorCode VARCHAR(30) NOT NULL,
                                                                                                                                                                                                                                                                                                                           SizeCode VARCHAR(10) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                Unit VARCHAR(10) NOT NULL DEFAULT 'Adet',
                                                                                                                                                                                                                                                                                                                                                                                  ListPrice NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                           StandardCost NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                       IsActive BOOLEAN NOT NULL DEFAULT TRUE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         CHECK (ListPrice > 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                AND StandardCost >= 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                AND StandardCost <= ListPrice));

-- 7. Satışlar (Otomatik Hesaplanan Kolonlarla Birlikte)

CREATE TABLE mock.Sale (SaleId BIGSERIAL PRIMARY KEY,
                                         OrderNo VARCHAR(40) NOT NULL,
                                                             OrderLineNo SMALLINT NOT NULL,
                                                                                  InvoiceNo VARCHAR(40),
                                                                                            SaleDate DATE NOT NULL,
                                                                                                          RequestedDate DATE NOT NULL,
                                                                                                                             ProductId INT NOT NULL REFERENCES mock.Product(ProductId),
                                                                                                                                                               BrandId INT NOT NULL REFERENCES mock.Brand(BrandId),
                                                                                                                                                                                               CustomerId INT NOT NULL REFERENCES mock.Customer(CustomerId),
                                                                                                                                                                                                                                  ProductCategoryId INT NOT NULL REFERENCES mock.ProductCategory(ProductCategoryId),
                                                                                                                                                                                                                                                                            DocumentType VARCHAR(10) NOT NULL CHECK (DocumentType IN ('SALE',
                                                                                                                                                                                                                                                                                                                                      'RETURN')), Quantity INT NOT NULL,
                                                                                                                                                                                                                                                                                                                                                               Unit VARCHAR(10) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                CurrencyCode CHAR(3) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                     UnitPrice NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                              UnitCost NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                      DiscountPct NUMERIC(5, 2) NOT NULL CHECK (DiscountPct BETWEEN 0 AND 100), SalesChannel VARCHAR(20) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         MarketCode CHAR(2) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            OrderStatus VARCHAR(20) NOT NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    GrossAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitPrice) STORED,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         NetAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitPrice * (1 - DiscountPct / 100.0)) STORED,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            CostAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitCost) STORED,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                MarginAmount NUMERIC(18, 2) GENERATED ALWAYS AS (Quantity * UnitPrice * (1 - DiscountPct / 100.0) - Quantity * UnitCost) STORED);

-- --- SABİT VERİLERİ (SEED) ---

INSERT INTO mock.Customer (ERPCustomerName, CustomerGroup, CountryCode, CurrencyCode)
VALUES ('H&M', 'H&M Group', 'SE', 'EUR'),
       ('ITX TRADING S.A', 'Inditex', 'ES', 'EUR'),
       ('EMEA ASPIRE TRADING FZE', 'Inditex EMEA', 'AE', 'EUR'),
       ('C&A Buying GmbH & Co. KG', 'C&A', 'DE', 'EUR'),
       ('PRIMARK LIMITED', 'Primark', 'GB', 'GBP'),
       ('LPP COMPANY', 'LPP', 'PL', 'EUR'),
       ('ASDA STORES LIMITED', 'ASDA', 'GB', 'GBP');


INSERT INTO mock.Brand (ERPBrandCode, BrandName, BrandGroup)
VALUES ('H&M', 'H&M', 'H&M Group'),
       ('ZAR', 'Zara', 'Inditex'),
       ('C&A', 'C&A', 'C&A'),
       ('BER', 'Bershka', 'Inditex'),
       ('PRI', 'Primark', 'Primark'),
       ('RSV', 'Reserved', 'LPP'),
       ('STR', 'Stradivarius', 'Inditex'),
       ('GEO', 'George', 'ASDA');


INSERT INTO mock.BrandCustomer (BrandId, CustomerId, IsPrimary)
VALUES (1,1,TRUE),
       (2,2,TRUE),
       (2,3,FALSE),
       (3,4,TRUE),
       (4,2,TRUE),
       (4,3,FALSE),
       (5,5,TRUE),
       (6,6,TRUE),
       (7,2,TRUE),
       (8,7,TRUE);


INSERT INTO mock.InventoryCategory (ERPProductGroup, DefaultUnit, IsFinishedProduct)
VALUES ('Aksesuar', 'Adet', FALSE),
       ('Boyalı Kumaş', 'Kg', FALSE),
       ('Ham Kumaş', 'Kg', FALSE),
       ('İplik', 'Kg', FALSE),
       ('Mamul', 'Adet', TRUE);


INSERT INTO mock.ProductCategory (ERPGroupName, ProductFamily, DecorationType)
VALUES ('Solid Top', 'Top', 'Solid'),
       ('Solid Elbise', 'Elbise', 'Solid'),
       ('Baskılı Tshirt', 'Tshirt', 'Baskılı'),
       ('Solid Tshirt', 'Tshirt', 'Solid'),
       ('Baskılı Sweatshirt', 'Sweatshirt', 'Baskılı'),
       ('Solid Pantolon', 'Pantolon', 'Solid'),
       ('Solid Bluz', 'Bluz', 'Solid'),
       ('Solid Etek', 'Etek', 'Solid'),
       ('Solid Sweatshirt', 'Sweatshirt', 'Solid'),
       ('Solid Body', 'Body', 'Solid'),
       ('Solid Şort', 'Şort', 'Solid'),
       ('Solid Legging', 'Legging', 'Solid'),
       ('Baskılı Top', 'Top', 'Baskılı'),
       ('Baskılı Elbise', 'Elbise', 'Baskılı'),
       ('Solid Atlet', 'Atlet', 'Solid'),
       ('Solid Jogger', 'Jogger', 'Solid'),
       ('Nakışlı Top', 'Top', 'Nakışlı'),
       ('Nakışlı Sweatshirt', 'Sweatshirt', 'Nakışlı'),
       ('Solid Jacket', 'Jacket', 'Solid'),
       ('Solid Cardigan', 'Cardigan', 'Solid');

-- 1000 Adet Ürün Üretme

INSERT INTO mock.Product (SKU, ModelCode, ProductName, BrandId, CustomerId, ProductCategoryId, SeasonCode, ColorCode, SizeCode, ListPrice, StandardCost)
SELECT 'MOCK-' || b.ERPBrandCode || '-' || LPAD(g::text, 6, '0'),
       'MDL-' || b.ERPBrandCode || '-' || LPAD((((g-1)/5)+1)::text, 5, '0'),
       b.BrandName || ' ' || pc.ERPGroupName || ' ' || LPAD(g::text, 6, '0'),
       b.BrandId,
    (SELECT CustomerId
     FROM mock.BrandCustomer
     WHERE BrandId = b.BrandId
     LIMIT 1), pc.ProductCategoryId, (ARRAY['SS25',
                                            'FW25',
                                            'SS26',
                                            'FW26',
                                            'CORE',
                                            'NOS'])[((g-1) % 6) + 1], (ARRAY['SİYAH',
                                                                             'BEYAZ',
                                                                             'LACİVERT',
                                                                             'GRİ',
                                                                             'KIRMIZI',
                                                                             'YEŞİL',
                                                                             'MAVİ',
                                                                             'BEJ'])[((g-1) % 8) + 1], (ARRAY['XS',
                                                                                                              'S',
                                                                                                              'M',
                                                                                                              'L',
                                                                                                              'XL',
                                                                                                              'XXL'])[((g-1) % 6) + 1], ROUND((8.00 + ((g * 17) % 7200) / 100.0)::numeric, 2),
                                                                                                                                        ROUND(((8.00 + ((g * 17) % 7200) / 100.0) * (0.46 + ((g * 7) % 15) / 100.0))::numeric, 2)
FROM generate_series(1, 1000) AS g
JOIN mock.Brand b ON b.BrandId = ((g-1) % 8) + 1
JOIN mock.ProductCategory pc ON pc.ProductCategoryId = ((g-1) % 20) + 1;

-- 50.000 Satırlık Satış ve İade Verisi Üretme

INSERT INTO mock.Sale (OrderNo, OrderLineNo, InvoiceNo, SaleDate, RequestedDate, ProductId, BrandId, CustomerId, ProductCategoryId, DocumentType, Quantity, Unit, CurrencyCode, UnitPrice, UnitCost, DiscountPct, SalesChannel, MarketCode, OrderStatus)
SELECT 'SO-' || EXTRACT(YEAR
                        FROM (DATE '2025-01-01' + ((g * 13) % 560))) || '-' || LPAD((((g-1)/3)+1)::text, 7, '0'),
       ((g-1) % 3) + 1,
       'INV-' || EXTRACT(YEAR
                         FROM (DATE '2025-01-01' + ((g * 13) % 560))) || '-' || LPAD((((g-1)/8)+1)::text, 7, '0'),
       DATE '2025-01-01' + ((g * 13) % 560),
       DATE '2025-01-01' + ((g * 13) % 560) + (14 + (g % 45)),
       p.ProductId,
       p.BrandId,
       p.CustomerId,
       p.ProductCategoryId,
       CASE
           WHEN g % 25 = 0 THEN 'RETURN'
           ELSE 'SALE'
       END,
       CASE
           WHEN g % 25 = 0 THEN -((g * 17) % 500 + 1)
           ELSE ((g * 17) % 500 + 1)
       END,
       p.Unit,
       'EUR',
       ROUND((p.ListPrice * (0.95 + ((g * 7) % 10) / 100.0))::numeric, 2),
       p.StandardCost,
       ROUND((((g * 19) % 2501) / 100.0)::numeric, 2),
       'B2B',
       'TR',
       CASE
           WHEN g % 20 = 0 THEN 'SHIPPED'
           ELSE 'INVOICED'
       END
FROM generate_series(1, 50000) AS g
JOIN mock.Product p ON p.ProductId = ((g-1) % 1000) + 1;

-- =====================================================
-- ASİSTAN İÇİN KOLAYLAŞTIRICI SANAL TABLOLAR (VIEWS)
-- =====================================================

CREATE OR REPLACE VIEW mock.iadeler AS
SELECT *
FROM mock.Sale
WHERE DocumentType = 'RETURN';


CREATE OR REPLACE VIEW mock.net_satislar AS
SELECT *
FROM mock.Sale
WHERE DocumentType = 'SALE';
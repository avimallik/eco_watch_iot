--------------------------------------------------------
--  File created - Thursday-February-05-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table TBL_ESP_IP
--------------------------------------------------------

  CREATE TABLE "ECOWATCHDB"."TBL_ESP_IP" 
   (	"ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE , 
	"IP" VARCHAR2(100 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;
REM INSERTING into ECOWATCHDB.TBL_ESP_IP
SET DEFINE OFF;
Insert into ECOWATCHDB.TBL_ESP_IP (ID,IP) values (63,'192.168.0.103');
Insert into ECOWATCHDB.TBL_ESP_IP (ID,IP) values (44,'192.168.0.196');
--------------------------------------------------------
--  Constraints for Table TBL_ESP_IP
--------------------------------------------------------

  ALTER TABLE "ECOWATCHDB"."TBL_ESP_IP" MODIFY ("ID" NOT NULL ENABLE);

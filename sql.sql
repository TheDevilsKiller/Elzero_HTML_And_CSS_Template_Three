SELECT 
/*+ optimizer_features_enable('11.1.0.7') */
DISTINCT 
SA.CHAR_PREM_ID AS CPOINT_ID  ,
CASE 
WHEN SA.CIS_DIVISION IN ('RCBU','JCBU','MCBU','TCBU') THEN GEOHCN.GEO_VAL
ELSE SP.SP_ID
END CONNECTION_ID  , 
BILL_METER.BADGE_NBR AS METER_NUMBER ,
BILL.BILL_ID ,
BILL.BILL_DT BILL_DATE,
CASE 
WHEN TRIM(BILL.CR_NOTE_FR_BILL_ID) IS NULL THEN 'B'
ELSE 'C'
END BILL_TYPE ,
TRIM(BILL.CR_NOTE_FR_BILL_ID) CR_FOR_BILL ,
BS.START_DT START_DATE ,
BS.END_DT END_DATE ,
BS_READ.START_READ_DATE  ,
BS_READ.START_READ_VALUE ,
BS_READ.END_READ_DATE ,
BS_READ.END_READ_VALUE ,
BS_READ.START_READ_TYPE,
BS_READ.END_READ_TYPE ,
BS_READ.START_READ_SOURCE,
BS_READ.END_READ_SOURCE ,
BSQ.BILL_SQ AS CONSUMPTION ,
SP.SP_ID ,
CASE 
WHEN B2.BILL_ID IS NOT NULL  THEN 'Y'
ELSE 'N'
END CORRECTED
FROM 
CI_SP SP , 
CI_SA_SP SASP ,
CI_BILL BILL 
LEFT OUTER JOIN CI_BILL B2 ON B2.CR_NOTE_FR_BILL_ID = BILL.BILL_ID ,
CI_SA_TYPE SAT,
CI_SA SA 
LEFT OUTER JOIN CISADM.CI_PREM_GEO GEOHCN ON GEOHCN.PREM_ID = SA.CHAR_PREM_ID AND GEOHCN.GEO_TYPE_CD = 'HCN' AND ROWNUM = 1 
LEFT OUTER JOIN (
SELECT MTR.BADGE_NBR , SA2.SA_ID 
FROM   CI_SP_MTR_HIST HIS ,CI_MTR_CONFIG GG , CI_MTR MTR , CI_SP SP2, CI_SA_SP SASP2 , CI_SA SA2
WHERE  GG.MTR_ID = MTR.MTR_ID
AND    GG.MTR_CONFIG_ID = HIS.MTR_CONFIG_ID 
AND    HIS.SP_ID  = SP2.SP_ID
AND    SP2.SP_ID  = SASP2.SP_ID
AND    SA2.SA_ID  = SASP2.SA_ID
AND    TRIM(HIS.REMOVAL_DTTM) IS NULL 
) BILL_METER ON BILL_METER.SA_ID = SA.SA_ID   ,
CI_BSEG BS 
LEFT OUTER JOIN(   
SELECT
BSN.BSEG_ID,
BSRN.START_REG_READING AS START_READ_VALUE ,
BSRN.END_REG_READING   AS END_READ_VALUE ,
BSRN.START_READ_DTTM   AS START_READ_DATE ,
BSRN.END_READ_DTTM     AS END_READ_DATE ,
CASE
WHEN REGN.READ_TYPE_FLG IN ('30','40') THEN 'Estimation'
WHEN SUBSTR(TO_CHAR(USN.USG_DATA_AREA) , INSTR(USN.USG_DATA_AREA , '<startReadEstimationIndicator>',1) + LENGTH('<startReadEstimationIndicator>'), 4) ='C1ES' THEN  'Estimation'
ELSE 'Actual'
END  AS START_READ_TYPE ,
CASE
WHEN REG2N.READ_TYPE_FLG IN ('30','40') THEN 'Estimation'
WHEN SUBSTR(TO_CHAR(USN.USG_DATA_AREA) , INSTR(USN.USG_DATA_AREA , '<endReadEstimationIndicator>',1) + LENGTH('<endReadEstimationIndicator>'), 4) ='C1ES' THEN  'Estimation'
ELSE 'Actual'
END  AS END_READ_TYPE ,
CASE 
WHEN TRIM(BSRN.USAGE_FLG)='X' THEN 'MDM'
ELSE TRIM(M_DATA.MR_SOURCE_CD)
END AS START_READ_SOURCE ,
CASE 
WHEN TRIM(BSRN.USAGE_FLG)='X' THEN 'MDM'
ELSE TRIM(M_DATA.MR_SOURCE_CD)
END AS END_READ_SOURCE 
FROM 
CI_BSEG BSN , 
CI_SA SAN , 
CI_SA_TYPE SATN ,
CI_BSEG_READ BSRN
LEFT OUTER JOIN CI_REG_READ REGN  ON BSRN.START_REG_READ_ID = REGN.REG_READ_ID
LEFT OUTER JOIN CI_REG_READ REG2N ON BSRN.START_REG_READ_ID = REG2N.REG_READ_ID
LEFT OUTER JOIN C1_USAGE USN      ON USN.BSEG_ID            = BSRN.BSEG_ID
LEFT OUTER JOIN (SELECT ML.DESCR  , ML.MR_SOURCE_CD , RR.REG_READ_ID   FROM CI_MR MM,CI_REG_READ RR ,CI_MR_SOURCE_L ML   WHERE MM.MR_ID = RR.MR_ID AND ML.MR_SOURCE_CD = MM.MR_SOURCE_CD AND ML.LANGUAGE_CD='ENG')M_DATA   ON  M_DATA.REG_READ_ID   = REGN.REG_READ_ID 
LEFT OUTER JOIN (SELECT ML.DESCR  , ML.MR_SOURCE_CD , RR.REG_READ_ID   FROM CI_MR MM ,CI_REG_READ RR ,CI_MR_SOURCE_L ML  WHERE MM.MR_ID = RR.MR_ID AND ML.MR_SOURCE_CD = MM.MR_SOURCE_CD AND ML.LANGUAGE_CD='ENG')M_DATA_2 ON  M_DATA_2.REG_READ_ID = REG2N.REG_READ_ID

WHERE SAN.SA_TYPE_CD       = SATN.SA_TYPE_CD
AND   SAN.CIS_DIVISION     = SATN.CIS_DIVISION
AND   BSN.BSEG_ID          = BSRN.BSEG_ID
AND   BSN.SA_ID            = SAN.SA_ID
AND   SATN.SVC_TYPE_CD       = 'W'
AND   TRIM(BSRN.USAGE_FLG) IN ( 'X', '+' ) 
) BS_READ ON BS_READ.BSEG_ID = BS.BSEG_ID
LEFT OUTER JOIN CI_BSEG_SQ BSQ ON BSQ.UOM_CD='M3' AND TRIM(SQI_CD) IS NULL AND BSQ.BSEG_ID  = BS.BSEG_ID
WHERE BILL.BILL_ID    = BS.BILL_ID
AND SA.SA_TYPE_CD     = SAT.SA_TYPE_CD
AND SA.CIS_DIVISION   = SAT.CIS_DIVISION
AND SA.SA_ID          = SASP.SA_ID
AND SP.SP_ID          = SASP.SP_ID
AND BS.SA_ID          = SA.SA_ID
AND SAT.SVC_TYPE_CD     = 'W'
AND BILL.BILL_STAT_FLG  = 'C';

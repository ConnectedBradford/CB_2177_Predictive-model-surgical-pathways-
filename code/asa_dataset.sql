CREATE TABLE CB_MYSPACE_Airelogic.los_mortality_asa_table AS 
(SELECT DISTINCT 
  a.person_id, 
  a.spell_number, 
  a.patient_age as Age,

  CAST(a.asa as INT) - 1 AS AsaLevel5,
  CASE
    WHEN CAST(a.asa as INT) > 2 THEN 1 
    ELSE 0
  END AS AsaLevel2,

  b.gender_source_value AS Sex,
  c.admission_method as AdmissionMethod,
  d.procedure_1 as Procedure,
  e.ImdDecile,
  CAST(f.In_Top_25 as INT) as LosWithinTop25,
  
  (
    SELECT ARRAY_TO_STRING(ARRAY_AGG(m.nameofmedication), "|"),
    FROM CB_FDM_PrimaryCare_V8.tbl_srprimarycaremedication m
    WHERE (
      a.person_id = m.person_id AND 
      date(m.datemedicationstart) <= date(a.surgery_date_time) AND 
      date(m.datemedicationend) >= date(a.surgery_date_time)
    )
  ) AS Medications,
  
  ( IFNULL (
    (
      SELECT 1
      FROM `CB_FDM_Warehouse_V3.cb_patient` p
      WHERE  
        a.person_id = p.person_id AND p.date_of_death IS NOT NULL AND p.date_of_death != "NULL" AND
        DATE_DIFF(date(FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m', p.date_of_death))), date(a.surgery_date_time), DAY) <= 30
    ), 0 )
  ) AS Mortality30Days
  
  FROM 
    `yhcr-prd-phm-bia-core.CB_FDM_Warehouse_V3.tbl_theatre`a
  LEFT JOIN 
    `CB_FDM_Warehouse_V3.person` b
  ON
    a.person_id = b.person_id
  LEFT JOIN
    `CB_FDM_Warehouse_V3.tbl_spell` c
  ON
    a.person_id = c.person_id AND a.spell_number = c.spell_number
  LEFT JOIN
    `CB_FDM_Warehouse_V3.tbl_episode` d
  ON 
    a.person_id = d.person_id AND a.spell_number = d.spell_number AND a.episode_serial = d.episode_number
  LEFT JOIN (
    SELECT DISTINCT person_id, MAX(Index_of_Multiple_Deprivation_Decile) AS ImdDecile
    FROM CB_LOOKUPS.tbl_IMD_by_LSOA i
    LEFT JOIN CB_LOOKUPS.tbl_person_lsoa p
    ON i.LSOA_code = p.lsoa
    GROUP BY person_id
  ) e
  ON a.person_id = e.person_id
  LEFT JOIN
    `CB_MYSPACE_Airelogic.length_of_stay` f
  ON 
    a.person_id = f.person_id AND a.spell_number = f.spell_number AND d.procedure_1 = f.Procedure  
  WHERE 
    a.asa IS NOT NULL AND a.asa != 'NULL' AND a.spell_number != "NULL"
)
 

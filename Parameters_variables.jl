
#variables: finance - climate - demand - energy - foodland - inventory - labourmarket - other - output - population - public - wellbeing
_inits = Dict{Symbol,Float64}(
    #finance
    :CCSD =>  0.15 + 0.005 + 0.02,
    :ELTI => 0.02,
    :PI => 0.02,
    :PU => 0.0326951,
    :CBSR => 0.02,

    #climate
    :N2OA => 1.052,
    :CH4A => 2.5,
    :CO2A => 2600,
    :ISCEGA => 12,
    :PWA => 0.4,
    :EHS => 0,

    #demand 
    :ETF2022 => 0, # No extra taxes before 2022
    :FGBW => 0.3, # Equal to fraction transfer in 1980
    :POCI => 7081, # It was OCI in 1980
    :WD => 7406.88,
    :PWCIN => 13000,
    :PGCIN => 5400,
    :GNI => 6531.07,
   
    #energy
    :EEPI2022 => 1,
    :REC => 300,
    :ACSWCF1980 => 10,
    :FEC => 980,

    #foodland
    :BALA => 3000,
    :CRLA => 1450,
    :GRLA => 3300,
    :FOLA => 1100,
    :OGFA => 2600,
    :SQICA => 1,
    :URLA => 215,

    #inventory
    :DELDI => 1,
    :EPP => 28087, # Taken from Vensim table
    :INV => 11234.8, # Taken from Vensim table
    :PRIN => 1, # Taken from Vensim table
    :PRI => 1,
    :RS => 28087,
    :SSWI => 1,

    #labourmarket
    :ECLR => 41,
    :ILPR => 0.8, # Taken from Vensim table
    # :LAPR => 7.343, # Taken from Vensim table
    :LAUS => 3060, # Taken from Vensim table
    :NHW => 2,
    :PURA => 0.05,
    :WARA => 3.6715, # Taken from Vensim table
    :WEOCLR => 1, # Taken from Vensim table
    :WF => 1530,
    :WSO => 0.5,

    #other
    :PGDPP => 6.4 * 0.93,

    #output
    :CUCPIS => 10072.5, # Taken from Vensim table
    :CUCPUS => 909.5, # Taken from Vensim table
    :ETFP => 1,
    # UNDOCUMENTED INITIALISATIONS
    :FACNC => 1.05149, # Taken from Vensim table
    :LAUS => 3060, # Taken from Labour and market sector
    :OLY => 26497.1, # Taken from Vensim table
    :WSO => 0.5, # Taken from Labour and market sector

    #population
    :A0020 => 2170,
    :A2040 => 1100,
    :A4060 => 768,
    :A60PL => 382,
    :DEATHS => 30,
    :EGDPP => 6.4,
    :EPA => 0,
    :LE => 67,
    :PA => 62,
    :PASS20 => 100,
    :PASS40 => 64,
    :PASS60 => 38,

    #public 
    :RTFPUA => 0, # Taken from Vensim table
    :TFPEE5TA => 1,

    #wellbeing
    :ORP => 0,
    :PAWBI => 0.65,
    :RD => 30,
    :STE => 1.3,
    :STR => 0.6,

)



#parameters: finance - climate - demand - energy - foodland - inventory - labourmarket - other - output - population - public - wellbeing
_params = Dict{Symbol,Float64}(
    
    #finance
    :GRCR => 0,
    :FSRT =>1,
    :NBOM => 0.015,
    :NBBM => 0.005,
    :NSR => 0.02,
    :IEFT => 10,
    :IPT => 1,
    :UPT => 1,
    :INSR => 0.7,
    :IT => 0.02,
    :UT => 0.05,
    :UNSR => -1.5,
    :SRAT => 1,

    #climate 
    :ERDN2OKF2022 => 0, # It was 0.01,
    :RDN2OKF => 0.01,
    :KN2OKF1980 => 0.11,
    :N2OA1980 => 1.052,
    :MAT => 5,
    :LN2OA => 95,
    :GN2OPP => 5,
    :ERDCH4KC2022 => 0, # It was 0.01,
    :RDCH4KC => 0.01,
    :KCH4KC1980 => 0.05,
    :CH4A1980 => 2.5,
    :LCH4A => 7.5,
    :GCH4PP => 5,
    :OBWA2022 => 1.35,
    :SOWLCO2 => 1,
    :LECO2A1980 => 60,
    :CO2A1850 => 2200,
    :TCO2PTCH4 => 2.75,
    :DACCO22100 => 0, # It was 8,
    :GCO2PP => 7.9,
    :TCO2ETN2O => 7,
    :TCO2ETCH4 => 23,
    :TCO2ETCO2 => 1,
    :ALGAV => 0.3,
    :ALIS => 0.7,
    :GLSU => 510,
    :ISCEGA1980 => 12,
    :TRSS1980 => 0.01,
    :MRS1980 => 0.0015,
    :WA1980 => 0.4,
    :SVDR => 4,
    :AI1980 => 55,
    :TPM3I => 0.95,
    :HRMI => 333,
    :OWWV => 0.18,
    :WVC1980 => 2,
    :WVF1980 => 0.9,
    :WVWVF => 3,
    :WFEH => 0.0006,
    :EH1980 => 0,
    :PD => 5,
    :TRSA1980 => 0.01,
    :CCCSt => 95,

    #demand
    :BITRW => 0.2,
    :EETF2022 => 0, # It was 0.02,
    :EGTRF2022 => 0, # It was 0.01,
    :EPTF2022 => 0, # It was 0.02,
    :ETGBW => 0, # It was 0.2,
    :FETACPET => 0.5,
    :FETPO => 0.5, # It was 0.8,
    :FGDC2022 => 0, # It was 0.1,
    :FT1980 => 0.3,
    :GCF => 0.75,
    :GDPOSR => -0.06,
    :GDPP1980 => 6.4,
    :GDDP => 10,
    :GEIC => 0, # It was 0.02,
    :GITRO => 0.3,
    :GPP => 200,
    :GSF2022 => 0,
    :INEQ1980 => 0.61,
    :ITRO1980 => 0.4,
    :ITRO2022 => 0.3,
    :OSF1980 => 0.9,
    :MATGF => 0.64,
    :MATWF => 0.39,
    :MWDB => 1,
    :MGDB => 1,
    :STR => 0.03,
    :TAB => 1,
    :TAOC => 1,
    :TAWC => 1,
    :TINT => 5,
    :WCF => 0.9,
    :WDP => 10,
    :WPP => 20,

    #energy
    :MNFCO2PP => 0.5,
    :FCO2SCCS2022 => 0,
    :GFCO2SCCS => 0.2, # It was 0.9,
    :CCCSt => 95,
    :ROCTCO2PT => -0.003,
    :EROCEPA2022 => 0.002, # It was 0.004,
    :NIEE => 0.01,
    :GFNE => 0.5, # It was 1,
    :FNE2022 => 0.03,
    :FNE1980 => 0,
    :EUEPRUNEFF => 3,
    :ECRUNEFF => 10,
    :GREF => 0.5, # It was 1,
    :REFF2022 => 0.23,
    :REFF1980 => 0.065,
    :RCUT => 3,
    :RECT => 3,
    :LREC => 40,
    :SWC1980 => 10,
    :CRDSWC => 0.2,
    :CAPEXRE1980 => 7,
    :CAPEXFED => 0.7,
    :OPEXRED => 0.001,
    :OPEXFED => 0.02,
    :CNED => 0.033,
    :FREH => 0,
    :KWEPKGH2 => 40,
    :TPTH2 => 10,
    :BEM => 0,
    :EFPP => 0.345,
    :TWHPEJCE => 278,
    :MTPEJCE => 24,
    :EKHPY => 8,
    :FECCT => 3,
    :NLFEC => 40,
    :sFCUTLOFC => 0.5,
    :NCUT => 8,
    :TCE => 0.03,
    :AFMCM => 1.35,
    :TCFFFNEU => 240,
    :TC => 0.02,

    #foodland 
    :AFGDP => 0.05,
    :CBECLE => -0.03,
    :CO2ARA => 1,
    :CO2C2022 => 420,
    :CO2CEACY => 0.3,
    :CO2RHFC => 65,
    :CRDRA => 0.05,
    :CTF => 500,
    :CYRA => 5,
    :DRC => 0.05,
    :ECRA22 => 400,
    :EGB22 => 5,
    :EROCFSP => 0,
    :FCG => 0.1,
    :FFLREOGRRM => -5,
    :FU80 => 61,
    :FUELER => 0.02,
    :FUESQ => -0.001,
    :GCWR => 0.05, # It was 0.2,
    :GFNRM => 0.1, # It was 0.5,
    :GFRA => 0.1, # It was 0.5,
    :KCKRM => 24,
    :LER80 => 0.004,
    :MFAM => 2,
    :OGRR80 => 0.004,
    :OW2022 => 1.35,
    :OWEACY => -0.3,
    :ROCFP => 0.01,
    :ROCFSP => 0.002,
    :SFU => 20,
    :SSP2LMA => 1,
    :TCTB => 0,
    :TFFLR => 0.2,
    :UDT => 10,
    :ULP => 0.05,

    #inventory 
    :DAT => 1.2,
    :DDI1980 => 1,
    :DIC => 0.4,
    :DRI => 1,
    :ICPT => 0.25,
    :MRIWI => 1.07,
    :OO => 28087,
    :PH => 0,
    :PPU => 1,
    :SAT => 1,
    :INVEODDI => -0.6,
    :INVEOIN => -0.26,
    :INVEOSWI => -0.6,
    :SRI => 1,
    :SWI1980 => 1,
    :TAS => 0.24,

    #labourmarket
    :AUR => 0.05,
    :FIC => 1,
    :GDPP1980 => 6.4, # Should be the same in Population
    :GDPPEROCCLRM => -0.1,
    :GENLPR => 0,
    :NLPR80 => 0.85,
    :PFTJ => 1,
    :PFTJ80 => 1,
    :PRUN => 1, # Taken from Vensim table
    :PUELPR => 0.05,
    :ROCECLR80 => 0.02,
    :RWER => 0.015,
    :TAHW => 5,
    :TENHW => -0.03,
    :TELLM => 5,
    :TYLD => 2.3,
    :WSOECLR => 1.05,
    :WSOELPR => 0.2,

    #other
    :TEGR => 4,
    :INELOK => -0.5,
    :NK => 0.3,

    #output
    :CAPPIS1980 => 59250,
    :CAPPUS1980 => 5350,
    :CC1980 => 1,
    :CTPIS => 1.5,
    :CTPUS => 1.5,
    :EMCUC => 1.7,
    :FCI => 0,
    :LAUS1980 => 3060, # Taken from Vensim table
    :LCPIS1980 => 15,
    :OW2022 => 1.35, # Taken from Climate sector
    :OWECCM => 0.2,
    :OWELCM => -0.1,
    :USPIS2022 => 0, # It was 0.01,
    :USPUS2022 => 0, # It was 0.01,
    # UNDOCUMENTED PARAMETERS
    :CBCEFRA => -0.8,
    :CU1980 => 0.8,
    :ED1980 => 1,
    :EDEFRA => 5,
    :EDELCM => 0.5,
    :FRA1980 => 0.9,
    :FRACAM => 0.65,
    :GDPP1980 => 6.4, # It should be the same as in the Labour and market sector
    :GDPPEFRACA => -0.2,
    :IPT => 1,
    :JOBS1980 => 1600,
    :KAPPA => 0.3,
    :LAMBDA => 0.7, # Calculated as 1-KAPPA
    :MA1980 => 0.25,
    :OG1980 => 0.06,
    :OO1980 => 28087, # Taken from Vensim table
    :PCORPIS => 2.3,
    :PCORPUS => 2.3,
    :TOED => 1,
    :WSOEFRA => -2.5,

    #population
    :CMFR => 0.01,
    :DNC80 => 4.3,
    :DNCA => 0,
    :DNCG => 0.14,
    :DNCM => 1.2,
    :EIP => 30,
    :EIPF => 0,
    :FP => 20,
    :FW => 0.5,
    :FADFS => 0.8,
    :GEFR => 0, # It was 0.2,
    :GEPA => 0,
    :LEA => 0.001,
    :LEEPA => 0.75,
    :LEG => 0.15,
    :LEMAX => 85,
    :MFM => 1.6,
    :MLEM => 1.1,
    :ORDER => 10,
    :OW2022 => 1.35,
    :OWELE => -0.02,
    :SSP2FA2022F => 1,
    :TAHI => 10,

    #public
    :CTA2022 => 9145,
    :CTPIS => 1.5, # Taken from Output sector
    :EDROTA2022 => 0.003,
    :DROTA1980 => 0.01,
    :FUATA => 0.3,
    :GDPTL => 15,
    :IIEEROTA => -0.1,
    :IPR1980 => 1.2,
    :IPRVPSS => 1,
    :IPT => 1, # Taken from Output sector
    :MIROTA2022 => 0, # It was 0.005,
    :OWETFP => -0.1,
    :SC1980 => 0.3,
    :SCROTA => 0.5,
    :XETAC2022 => 0,
    :XETAC2100 => 0,
    :OW2022 => 1.35,

    #wellbeing
    :AI => 0.6,
    :AP => 0.02,
    :AWBPD => 9,
    :DRDI => 0.5,
    :DRPS => 0.7,
    :EIP => 30,
    :EIPF => 0,
    :GWEAWBGWF => -0.58,
    :IEAWBIF => -0.6,
    :MWBGW => 0.2,
    :NRD => 30,
    :PESTF => -15,
    :PAEAWBF => 0.5,
    :PREAWBF => 6,
    :SPS => 0.3,
    :STEERDF => 1,
    :STRERDF => -1,
    :TCRD => 10,
    :TDI => 15,
    :TEST => 10,
    :TI => 0.5,
    :TP => 0.8,
    :TPR => 0.02,
    :TPS => 3,
    :TW => 1,
    
)
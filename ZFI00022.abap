*&---------------------------------------------------------------------*
*& Report  ZFI00022
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

report  zfi00022.

tables: zmkpf,zmseg.

tables mara .
tables mbew .
tables t001k .
include zfuncmu4.

select-options: s_matnr for mara-matnr,
                s_matkl for mara-matkl,
                s_bukrs for zmseg-bukrs,
                s_werks for zmseg-werks,
                s_bwart for zmseg-bwart.
selection-screen uline.
parameters: p_budat like zmkpf-budat default sy-datum.
parameters: p_days(4) type i default 360.

selection-screen uline.
parameters: p_matkl as checkbox default 'X'.

data begin of imara occurs 0.
data: matnr like mara-matnr,
      matkl like mara-matkl.
data end of imara.

data mgp like imara occurs 0 with header line.

data begin of ialv occurs 0 .
data: matnr like mara-matnr,
      matkl like mara-matkl,
      maktx like makt-maktx,
      bukrs like zmseg-bukrs,
      werks like zmseg-werks,
      menge like zmseg-menge,
      compr like mbew-stprs,
      salk3 like mbew-salk3,
      maxdt like sy-datum,
      maxbw like zmseg-bwart,
      maxds type i.
data end of ialv.

data xalv like ialv occurs 0 with header line.

data is_post like sy-calld.

data: sdate like sy-datum,
      edate like sy-datum.

data imbew type mbew.

data izmseg like zmseg occurs 0 with header line.
data xzmseg like zmseg occurs 0 with header line.
data xmax   like zmseg occurs 0 with header line.

ranges f_matnr for mara-matnr.

initialization.

  s_bwart-sign = 'I' .
  s_bwart-option = 'EQ' .
  s_bwart-low = '101' .
  append s_bwart.

  s_bwart-low = '531' .
  append s_bwart.

  s_bwart-low = '675' .
  append s_bwart.

  s_bwart-low = '161' .
  append s_bwart.

  s_bwart-low = '657' .
  append s_bwart.

  s_bwart-low = '653' .
  append s_bwart.
*
  s_bwart-low = '601' .
  append s_bwart.

start-of-selection.

  f_matnr-sign = 'I' .
  f_matnr-option = 'BT' .
  f_matnr-low = 'A*' .
  f_matnr-high = 'Z*' .
  append f_matnr.


  if p_budat is initial.
    edate = sy-datum .
    sdate = edate - p_days .
  else.
    edate = p_budat.
    sdate = edate - p_days .
  endif.
*  p_budat =  p_budat - 360 .
  perform get_imara .
  perform get_matnr_max_budat .
  perform adjust_imara_budat .
*  perform get_matnr_gt_360 .

  perform get_matnr_stock  .
  perform get_matnr_value  .
  perform adjust_ialv.

  if p_matkl = 'X' .
    perform show_ialv tables xalv using 'X'.
  else.
    perform show_ialv tables ialv using ''.
  endif.

*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
form user_command  using r_ucomm like sy-ucomm
                                rs_selfield type slis_selfield.

  data: lr_grid type ref to cl_gui_alv_grid,
        myindex type sy-tabix.

  check p_matkl = 'X'.

  call function 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    importing
      e_grid = lr_grid.
  call method lr_grid->check_changed_data.
  rs_selfield-refresh = 'X'.

  case r_ucomm.
    when '&IC1' .
      perform process_ucomm_ic1 using rs_selfield-tabindex .

  endcase.

endform .                    "user_command

*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->RT_EXTAB   text
*----------------------------------------------------------------------*
form set_pf_status using rt_extab type slis_t_extab.
  "去激活Function code为&ETA的详情按钮
*  append '&ETA'  to  rt_extab.
*  append '&DATA_SAVE'  to  rt_extab.
  set pf-status 'STANDARD' of program sy-repid .
*    excluding rt_extab.
endform.                    "set_pf_status
*&---------------------------------------------------------------------*
*&      Form  GET_MATNR_GT_360
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_matnr_gt_360 .

  loop at mgp .
    if mgp-matkl = 'D' or mgp-matkl = 'DH' .
      perform process_imara_by_matnr .
    else.
      perform process_imara_by_matkl .
    endif.
  endloop.

endform.                    " GET_MATNR_GT_360
*&---------------------------------------------------------------------*
*&      Form  GET_IMARA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_imara .

  select matnr matkl from mara into corresponding fields of table imara
    where matnr in s_matnr
      and matnr in f_matnr
      and matkl in s_matkl .

  sort imara by matkl .

  delete imara where matkl = 'DEDSD' .
  delete imara where matkl = 'DH02'  .

  mgp[] = imara[].

  delete adjacent duplicates from mgp comparing matkl .

endform.                    " GET_IMARA
*&---------------------------------------------------------------------*
*&      Form  PROCESS_IMARA_BY_MATKL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_imara_by_matkl .

  clear is_post.

  loop at imara where matkl = mgp-matkl.
    select max( budat ) from zmseg into corresponding fields of zmseg
        where matnr = imara-matnr
        and bwart in s_bwart
        and bukrs in s_bukrs
        and werks in s_werks
        and ( budat > sdate and budat <= edate ).

    if sy-subrc = 0 .
      is_post = 'X' .
      exit .
    endif.
  endloop.

  if is_post = 'X' .
    delete imara where matkl = mgp-matkl .
  endif.

endform.                    " PROCESS_IMARA_BY_MATKL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_IMARA_BY_MATNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_imara_by_matnr .

  loop at imara where matkl = mgp-matkl.
    select single * from zmseg into corresponding fields of zmseg
        where matnr = imara-matnr
        and bwart in s_bwart
        and bukrs in s_bukrs
        and werks in s_werks
        and ( budat > sdate and budat <= edate ).

    if sy-subrc = 0 .
      delete imara .
    endif.

  endloop.

endform.                    " PROCESS_IMARA_BY_MATNR
*&---------------------------------------------------------------------*
*&      Form  GET_MATNR_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_matnr_stock .

  loop at imara .
    select * from zmseg into corresponding fields of ialv
      where matnr = imara-matnr
        and bukrs in s_bukrs
        and werks in s_werks
        and budat <= edate.
      ialv-matkl = imara-matkl .
      collect ialv . clear ialv.
    endselect.
  endloop.

  delete ialv where menge = 0 .

  sort ialv .

endform.                    " GET_MATNR_VALUE
*&---------------------------------------------------------------------*
*&      Form  SHOW_IALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form show_ialv  tables  p_ialv structure ialv
                 using  p_compr.

  perform initial_alv_layout.

  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZF22'
    tables
      fieldcat = gt_fieldcat[].

  loop at gt_fieldcat where fieldname = 'MENGE' .
    gt_fieldcat-decimals_out = 0 .
    modify gt_fieldcat.
  endloop.

  if p_compr = 'X' .
    delete gt_fieldcat where fieldname = 'COMPR' .
  endif.

  call function 'REUSE_ALV_GRID_DISPLAY'
    exporting
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      is_layout                = gs_layout
      it_fieldcat              = gt_fieldcat[]
      i_save                   = 'C'
    tables
      t_outtab                 = p_ialv
    exceptions
      program_error            = 1
      others                   = 2.

endform.                    " SHOW_IALV
*&---------------------------------------------------------------------*
*&      Form  GET_MATNR_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_matnr_value .

  loop at ialv .

    clear imbew.

    call function 'ZPRO_GET_MBEW_PRICE'
      exporting
        matnr      = ialv-matnr
        bwkey      = ialv-werks
        from_mbewh = 'X'
        budat      = edate
      importing
        lmbew      = imbew.


    if imbew-vprsv = 'S' .
      ialv-compr = imbew-stprs / imbew-peinh .
      ialv-salk3 = ialv-menge * ialv-compr .
    elseif imbew-vprsv = 'V' .
      ialv-compr = imbew-verpr / imbew-peinh .
      ialv-salk3 = ialv-menge * ialv-compr  .
    endif    .

    call function 'ZPRO_GET_MATNR_TEXT'
      exporting
        matnr         = ialv-matnr
*       SPRAS         = '1'
      importing
        maktx         = ialv-maktx  .

    modify ialv.
  endloop .

endform.                    " GET_MATNR_VALUE
*&---------------------------------------------------------------------*
*&      Form  ADJUST_IALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form adjust_ialv .

  data l_wgbez like t023t-wgbez.

  loop at ialv.

    clear xmax.
    read table xmax with key matnr = ialv-matnr
                             werks = ialv-werks .

    if sy-subrc = 0.

      ialv-maxdt = xmax-budat .
      ialv-maxbw = xmax-bwart .
      ialv-maxds = edate - xmax-budat .

      if ialv-maxds < p_days.

        delete ialv where matkl = ialv-matkl
                      and werks = ialv-werks.

      else.
        modify ialv .
      endif.
    endif.
  endloop.

  if p_matkl = 'X' .
    clear xalv[] . clear xalv.
    loop at ialv.
      if ialv-matkl ='D' or ialv-matkl = 'DH' .
        move-corresponding ialv to xalv.
        append xalv . clear xalv .
      else.
        move-corresponding ialv to xalv .
        clear xalv-matnr.
        clear xalv-compr.
        clear l_wgbez.
        clear: xalv-maxdt,xalv-maxbw,xalv-maxds .

        call function 'ZPRO_GET_MATKL_TEXT'
          exporting
            matkl         = xalv-matkl
          importing
            wgbez         = l_wgbez
*         WGBEZ60       =
                  .
        xalv-maktx = l_wgbez .
        collect xalv. clear xalv.

      endif.
    endloop.
  endif.


endform.                    " ADJUST_IALV
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_IC1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_RS_SELFIELD  text
*----------------------------------------------------------------------*
form process_ucomm_ic1  using    p_rs_selfield.

  data lalv like ialv occurs 0 with header line.

  read table xalv index p_rs_selfield .

  clear lalv[].
  loop at ialv where matkl = xalv-matkl and werks = xalv-werks.
    move-corresponding ialv to lalv.
    append lalv . clear lalv.
  endloop.

  perform show_ialv tables lalv using '' .

endform.                    " PROCESS_UCOMM_IC1
*&---------------------------------------------------------------------*
*&      Form  GET_MATNR_MAX_BUDAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_matnr_max_budat .

  data it001k like t001k occurs 0 with header line.
  data imax like izmseg occurs 0 with header line.

  select * from t001k into corresponding fields of table it001k
    where bukrs in s_bukrs
      and bwkey in s_werks.

  loop at imara .
    clear izmseg[] . clear izmseg.
    select * from zmseg into corresponding fields of table izmseg
      where matnr = imara-matnr
        and budat <= edate
        and bukrs in s_bukrs
        and werks in s_werks
        and bwart in s_bwart.
*    append lines of izmseg to xzmseg.

    loop at it001k.
      clear imax[] . clear imax.
      loop at izmseg where werks = it001k-bwkey.
        move-corresponding izmseg to imax .
        append imax. clear imax .
      endloop.

      if not imax[] is initial.
        sort imax by budat descending.
        read table imax index 1 .
        move-corresponding imax to xmax .
        append xmax . clear xmax .
      endif.
    endloop.
  endloop.

endform.                    " GET_MATNR_MAX_BUDAT
*&---------------------------------------------------------------------*
*&      Form  ADJUST_IMARA_BUDAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form adjust_imara_budat .

  data begin of lmgp occurs 0.
          include structure xmax.
  data matkl like mara-matkl .
  data end of lmgp.

  data xmgp like lmgp occurs 0 with header line.

  data l_matkl like sy-calld.
  data l_budat like sy-datum.

*  loop at xmax .
*    clear imara.
*    read table imara with key matnr = xmax-matnr.
*
*    move-corresponding xmax to lmgp .
*    lmgp-matkl = imara-matkl .
*    append lmgp . clear lmgp .
*  endloop.
*
*  xmgp[] = lmgp[].
*  sort xmgp by matkl .
*  delete adjacent duplicates from xmgp comparing matkl .
*
*
*  l_budat = edate - p_days .
*
*  loop at xmgp.
*    clear l_matkl .
*    loop at lmgp where matkl = xmgp-matkl.
*      if lmgp-budat > l_budat .
*        l_matkl = 'X' .
*      endif.
*    endloop.
*    if l_matkl = 'X' .
*      delete imara where matkl = xmgp-matkl .
*    endif.
*  endloop.

endform.                    " ADJUST_IMARA_BUDAT

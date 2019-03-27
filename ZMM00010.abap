*----------------------------------------------------------------------*
* Program Name: ZMM00010
* Project     : N/A
* Author      : Zhou Jun
* Date        : 2017.7.31
* Module      : N/A
* Description : Stock List
*
*
* Special features: N/A
*
*
*----------------------------------------------------------------------*
* Modifications:
* Author      Date     Commented as  Description
*-----------  --------  -----------  ----------------------------------*
*
*----------------------------------------------------------------------*

report  zmm00010 no standard page heading line-size 172 line-count 0.

include zfuncmu4.

tables mard .
tables mcha .
tables mchb .
tables marc .
tables makt .

tables zmat .
tables zmat1 .
tables mara .

tables  zs06t .

select-options: s_matnr for mard-matnr,
                s_werks for mard-werks,
                s_lgort for mard-lgort,
                s_charg for mchb-charg.

selection-screen uline .

parameters p_mchb as checkbox default 'X'.
parameters ck_vfdat as checkbox .

parameters: day20 type i default 360.
*            day30 type i default 180.

data imard like mard occurs 0 with header line.
data imchb like mchb occurs 0 with header line.

data begin of ialv occurs 0 .
data: matnr like mard-matnr,
      maktx like makt-maktx,
      werks like mard-werks,
      lgort like mard-lgort,
      charg like mchb-charg,
      labst like mard-labst,
      umlme like mard-umlme,
      insme like mard-insme,
      einme like mard-einme,
      speme like mard-speme,
      retme like mard-retme,
      omeng like vbbe-omeng,
      hsdat like mcha-hsdat,
      vfdat like mcha-vfdat,
      normt like zmat-normt,
      groes like zmat-groes,
      meins(10) type c,
      activ like mard-labst,
      ckday type i .

data end of ialv.

data: begin of xtab4 occurs 0,         "交货计划
       matnr like vbbe-matnr,
       werks like vbbe-werks,
       lgort like vbbe-lgort,
       charg like vbbe-charg,
       vbmna like vbbe-omeng,
       vbmnb like vbbe-omeng,
       vbmnc like vbbe-omeng,
       vbmne like vbbe-omeng,
       vbmng like vbbe-omeng,
       vbmni like vbbe-omeng,
       omeng like vbbe-omeng,
       vrkme like vbep-vrkme,
       wmeng like vbep-wmeng,


     end of xtab4.

start-of-selection.

  perform get_imard.

  perform get_xtab4.

  perform get_imchb .

  perform get_ialv .

  perform adjust_ialv.

  if p_mchb = 'X' and ck_vfdat = 'X' .
    perform process_check_vfdat .
  endif.

  perform show_ialv.

*&---------------------------------------------------------------------*
*&      Form  GET_IMARD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_imard .

  select * from mard into corresponding fields of table imard
    where matnr in s_matnr
      and werks in s_werks
      and lgort in s_lgort .

  delete imard where ( labst is initial and umlme is initial and insme is initial
                 and   einme is initial and speme is initial and retme is initial ) .

endform.                    " GET_IMARD
*&---------------------------------------------------------------------*
*&      Form  GET_IMCHB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_imchb .

  check p_mchb = 'X' .

  loop at imard.

    select * from mchb appending corresponding fields of table imchb
      where matnr = imard-matnr
        and werks = imard-werks
        and lgort = imard-lgort
        and charg in s_charg.

  endloop .

  delete imchb where ( clabs is initial and cumlm is initial
                 and   cinsm is initial and ceinm is initial
                 and   cspem is initial and cretm is initial ) .
endform.                    " GET_IMCHB
*&---------------------------------------------------------------------*
*&      Form  GET_IALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_ialv .

  if p_mchb = 'X' .
    perform get_ialv_by_mchb .
  else.
    perform get_ialv_by_mard .
  endif.

endform.                    " GET_IALV
*&---------------------------------------------------------------------*
*&      Form  GET_IALV_BY_MARD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_ialv_by_mard .

  data l_omeng like vbbe-omeng .

  loop at imard.
    move-corresponding imard to ialv.


    perform collect_omeng using ialv-matnr ialv-werks ialv-lgort
                       changing ialv-omeng.

    append ialv.
  endloop.

endform.                    " GET_IALV_BY_MARD
*&---------------------------------------------------------------------*
*&      Form  GET_IALV_BY_MCHB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_ialv_by_mchb .

  loop at imard.

    clear marc .
    select single xchar into marc-xchar from marc
      where matnr = imard-matnr
        and werks = imard-werks .

    if marc-xchar = 'X' .

      perform appending_ialv_by_mchb using imard-matnr imard-werks imard-lgort .


    else.

      move-corresponding imard to ialv.
      perform collect_omeng using ialv-matnr ialv-werks ialv-lgort
                   changing ialv-omeng.

      append ialv.

    endif.

  endloop.


endform.                    " GET_IALV_BY_MCHB
*&---------------------------------------------------------------------*
*&      Form  SHOW_IALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form show_ialv .

  clear gt_fieldcat[] . clear gt_fieldcat.

  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZM10'
    tables
      fieldcat = gt_fieldcat[].

  perform initial_alv_layout.

  if ck_vfdat is initial .

    delete gt_fieldcat where fieldname = 'CKDAY' .
  endif.

  call function 'REUSE_ALV_GRID_DISPLAY'
    exporting
      i_callback_program = sy-repid
      is_layout          = gs_layout
      i_grid_title       = 'MD Stock API(K2-1) Report'
      it_fieldcat        = gt_fieldcat[]
      i_save             = 'C'
    tables
      t_outtab           = ialv
    exceptions
      program_error      = 1
      others             = 2.

endform.                    " SHOW_IALV
*&---------------------------------------------------------------------*
*&      Form  GET_XTAB4
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_xtab4 .

  data l_tab4 like xtab4 occurs 0 with header line.
  data l_mard like imard occurs 0 with header line.

  ranges i_werks for mard-werks .

  l_mard[] = imard[].

  sort l_mard by matnr.

  delete adjacent duplicates from l_mard comparing matnr.

  loop at l_mard.

    clear l_tab4. refresh l_tab4.
    call function 'MB_SELECT_SD_SCHEDULED_STOCK' "交货计划
      exporting
        x_matnr = l_mard-matnr
        x_kzwso = ''
      tables
        xtab4   = l_tab4
        xwerks  = i_werks.

    append lines of l_tab4 to xtab4 .

  endloop.

endform.                                                    " GET_XTAB4
*&---------------------------------------------------------------------*
*&      Form  APPENDING_IALV_BY_MCHB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IMARD_MATNR  text
*      -->P_IMARD_WERKS  text
*      -->P_IMARD_LGORT  text
*----------------------------------------------------------------------*
form appending_ialv_by_mchb  using    p_imard_matnr
                                      p_imard_werks
                                      p_imard_lgort.

  loop at imchb where matnr = p_imard_matnr
                   and werks = p_imard_werks
                   and lgort = p_imard_lgort .

    ialv-matnr = imchb-matnr.
    ialv-werks = imchb-werks.
    ialv-lgort = imchb-lgort.
    ialv-charg = imchb-charg.
    ialv-labst = imchb-clabs.
    ialv-umlme = imchb-cumlm.
    ialv-insme = imchb-cinsm.
    ialv-einme = imchb-ceinm.
    ialv-speme = imchb-cspem.
    ialv-retme = imchb-cretm.

    clear xtab4 .
    read table xtab4 with key matnr = ialv-matnr
                              werks = ialv-werks
                              lgort = ialv-lgort
                              charg = ialv-charg.

    ialv-omeng = xtab4-omeng .
    append ialv . clear ialv.

  endloop.


endform.                    " APPENDING_IALV_BY_MCHB
*&---------------------------------------------------------------------*
*&      Form  COLLECT_OMENG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IALV_MATNR  text
*      -->P_IALV_WERKS  text
*      -->P_IALV_LGORT  text
*      <--P_IALV_OMENG  text
*----------------------------------------------------------------------*
form collect_omeng  using    p_ialv_matnr
                             p_ialv_werks
                             p_ialv_lgort
                    changing p_ialv_omeng.


  clear p_ialv_omeng.

  loop at xtab4 where matnr = p_ialv_matnr
                   and werks = p_ialv_werks
                   and lgort = p_ialv_lgort .


    p_ialv_omeng = xtab4-omeng + p_ialv_omeng .

  endloop.



endform.                    " COLLECT_OMENG
*&---------------------------------------------------------------------*
*&      Form  ADJUST_IALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form adjust_ialv .

  data l_matnr like mard-matnr.
  data meins_text(10) type c.

  loop at ialv.

    clear makt.
    select single maktx from makt into makt-maktx
      where matnr = ialv-matnr
        and spras = '1' .
    ialv-maktx = makt-maktx .

    select single meins from mara into mara-meins
      where matnr = ialv-matnr.

    call function 'ZPRO_GET_MEINS_TEXT'
      exporting
        meins      = mara-meins
        spras      = '1'
      importing
        meins_text = meins_text.

    ialv-meins = meins_text .

    clear zmat .
    clear zmat1 .

    call function 'ZPRO_GET_MATERIAL_ADD_ONS'
      exporting
        matnr = ialv-matnr
        charg = ialv-charg
      importing
        zmat  = zmat
        zmat1 = zmat1.

    ialv-normt = zmat-normt .
    ialv-groes = zmat-groes .
    ialv-maktx = makt-maktx .
    ialv-normt = zmat-normt .
    ialv-groes = zmat-groes .
    ialv-meins = meins_text .

    ialv-activ = ialv-labst - ialv-omeng.

    call function 'ZPRO_GET_MATERIAL_HSDAT'
      exporting
        matnr = ialv-matnr
        charg = ialv-charg
        werks = ialv-werks
      importing
        hsdat = ialv-hsdat
        vfdat = ialv-vfdat.

    modify ialv.

    l_matnr = ialv-matnr.
  endloop.

endform.                    " ADJUST_IALV
*&---------------------------------------------------------------------*
*&      Form  PROCESS_CHECK_VFDAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_check_vfdat .

  data l_mara like mara occurs 0 with header line.
  data l_alv like ialv occurs 0 with header line.
  data ck_day type i .

  l_alv[] = ialv[] .

  sort l_alv by matnr .
  delete adjacent duplicates from l_alv comparing matnr .

*  loop at l_alv.
*    clear mara.
*    select single * from zs06t into corresponding fields of zs06t
*      where matnr = l_alv-matnr.
*
*    l_mara-matnr = zs06t-matnr.
*    l_mara-spart = zs06t-matnrc.
*
*    append l_mara . clear l_mara .
*  endloop.

  loop at ialv.

*    clear l_mara .
*    read table l_mara with key matnr = ialv-matnr .

    ck_day = ialv-vfdat - sy-datum .

*    case l_mara-spart .
*      when '20' .
*        ck_day = ck_day - day20 .
*        if ck_day >= 0 .
*          delete ialv .
*        endif.
*      when '30' .
*        ck_day = ck_day - day30 .
*        if ck_day >= 0 .
*          delete ialv .
*        endif.
*      when others .
*        delete ialv.
    ck_day = ck_day - day20 .

    if ck_day >= 0 .
      delete ialv .
    else.
      ialv-ckday = ck_day .
      modify ialv.
    endif.

  endloop.

endform.                    " PROCESS_CHECK_VFDAT

*&---------------------------------------------------------------------*
*&  Include           ZBC00009
*&---------------------------------------------------------------------*
type-pools: slis.

tables zalvt.

data: gt_fieldcat type  slis_t_fieldcat_alv with header line,
      gs_layout   type  slis_layout_alv,
      gt_events   type  slis_t_event.

data: it_listheader type slis_t_listheader ,
      it_event type slis_t_event.

data: gt_zcrse like zcrse occurs 0 with header line.

*&---------------------------------------------------------------------*
*&      Form  PROCESS_FULL_OF_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1641   text
*----------------------------------------------------------------------*
form initial_alv_layout.

  gs_layout-zebra          = 'X'.  "设置每行的背景颜色交错显示。
  gs_layout-colwidth_optimize = 'X'.  "ALV输出时候自动优化宽度
  gs_layout-detail_popup   = 'X'.
  gs_layout-no_subtotals   = ''.

endform.                    " PROCESS_FULL_OF_FIELDCAT



*&---------------------------------------------------------------------*
*&      Form  PROCESS_FULL_OF_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1641   text
*----------------------------------------------------------------------*
form process_full_of_fieldcat  using p_alvnr.

  clear  gt_fieldcat[].  clear  gt_fieldcat.

  select * from zalvt into corresponding fields of zalvt
    where alvnr = p_alvnr.

    gt_fieldcat-fieldname    = zalvt-alvfd.
    gt_fieldcat-ref_tabname  = ''.
    gt_fieldcat-seltext_m    = zalvt-alvtx.
    "    gt_fieldcat-outputlen    = 10.
    gt_fieldcat-no_zero      =  zalvt-no_zero .
    gt_fieldcat-emphasize    =  zalvt-color .
    append gt_fieldcat.
    clear  gt_fieldcat.
  endselect.

endform.                    " PROCESS_FULL_OF_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_CONCATENATE_FIELD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_XALV_DL  text
*      <--P_L_DL  text
*----------------------------------------------------------------------*
form process_concatenate_field  using    in_text
                                changing out_text .

  check not in_text is initial.

  call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
    exporting
      input  = in_text
    importing
      output = in_text.

  if out_text is initial.
    out_text = in_text .
  else.
    search out_text for in_text.
    if sy-subrc <> 0.
      concatenate out_text ',' in_text into out_text.
    endif.
  endif.

endform.                    " PROCESS_CONCATENATE_FIELD
*&---------------------------------------------------------------------*
*&      Form  ADJUST_GT_FIELDCAT_X1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form adjust_gt_fieldcat_x1 .

  loop at gt_fieldcat .
    case gt_fieldcat-fieldname .
      when 'MESSAGE' .
        gt_fieldcat-outputlen = 60.
      when 'ARKTX' .
        gt_fieldcat-outputlen = 40.
      when 'ERDAT' .
        gt_fieldcat-outputlen = 10.
      when 'SEL' .
        gt_fieldcat-outputlen = 4.
      when 'CHARG' .
        gt_fieldcat-outputlen = 10.
      when 'MATNR' .
        gt_fieldcat-outputlen = 18.
      when 'WERKS' or 'LGORT' .
        gt_fieldcat-outputlen = 8.
      when 'VBELN' or 'CRSNR' .
        gt_fieldcat-outputlen = 10.
      when 'POSNR' or 'CRSNP' or 'ZTERM' .
        gt_fieldcat-outputlen = 8.
      when 'BSTNK' .
        gt_fieldcat-outputlen = 25.
    endcase .

    modify gt_fieldcat.
  endloop.

endform.                    " ADJUST_GT_FIELDCAT_X1
*&---------------------------------------------------------------------*
*&      Form  PROCESS_SHOW_ZCRSE_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IZF18S_CRSNR  text
*----------------------------------------------------------------------*
form process_show_zcrse_alv  using    p_crsnr.

  check not p_crsnr is initial.

  clear gt_zcrse[] .
  select * from zcrse into corresponding fields of table gt_zcrse
    where crsnr = p_crsnr .


  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZCRSE'
    tables
      fieldcat = gt_fieldcat[].

  perform initial_alv_layout.

    call function 'REUSE_ALV_GRID_DISPLAY'
    exporting
      i_callback_program       = sy-repid
      is_layout                = gs_layout
      i_grid_title             = 'ZCRSE Messages'
      it_fieldcat              = gt_fieldcat[]
      i_save                   = 'C'
    tables
      t_outtab                 = gt_zcrse[]
    exceptions
      program_error            = 1
      others                   = 2.





endform.                    " PROCESS_SHOW_ZCRSE_ALV

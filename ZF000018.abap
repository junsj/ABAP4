*&---------------------------------------------------------------------*
*& Report  ZFI00018
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

report  zfi00018..

tables zf18s .
tables zf18h .
include zfuncmu4 .
include zfuncmu5 .
include zfuncmu10.


selection-screen begin of block b2 with frame title text-002.
parameters: p_mjahr like zf18s-mjahr default sy-datum(4).
select-options: s_month for zf18s-month_j, "  default sy-datum+4(2),
                s_monthf for zf18s-month_f,
                s_sales for zf18s-sales,
                s_div   for zf18s-division.
selection-screen end of block b2.

selection-screen begin of block b3 with frame title text-003.
parameters: p_nosend as checkbox.

selection-screen end of block b3.

selection-screen skip .

selection-screen begin of block b1 with frame title text-001.
parameters: ps_parm(20) as listbox visible length 20 .
parameters: p_file type string.
selection-screen begin of line.
selection-screen pushbutton (18) but1 user-command upload.
selection-screen pushbutton 33(18) but2 user-command download.
selection-screen end of line.
selection-screen end of block b1.


data begin of izf18s occurs 0.
        include structure zf18s .
data: sel like sy-calld,
      message like bapiret2-message,
      smtp_addr like zwf7a-smtp_addr.
data end of izf18s.

data izf18h like zf18h occurs 0 with header line.

data c18 like zf18s occurs 0 with header line.


constants p_py(100) type c value 'E:\SAPEDI\ZF18\ZF18.py'.


at selection-screen on value-request for p_file.

  perform get_file_name_dialog changing p_file .


at selection-screen output.
  perform appending_down_list .

at selection-screen.

  case sy-ucomm.
    when 'UPLOAD' .
      perform process_ucomm_upload.
    when 'DOWNLOAD' .
      perform process_ucomm_download.
  endcase.

initialization.

  call function 'ICON_CREATE' " 给按钮添加图标和文本
     exporting
       name   = 'ICON_IMPORT'    " 按钮的图片的名字
       text   = '上传'                   "按钮的文本
       info   = 'Import'
     importing
       result = but1
     exceptions
       others = 0.

  call function 'ICON_CREATE' " 给按钮添加图标和文本
     exporting
       name   = 'ICON_SEARCH'    " 按钮的图片的名字
       text   = '下载模板'                   "按钮的文本
       info   = 'Search'
     importing
       result = but2
     exceptions
       others = 0.


start-of-selection.

  perform get_izf18s_from_db .

  perform show_izf18s .

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

  call function 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    importing
      e_grid = lr_grid.
  call method lr_grid->check_changed_data.
  rs_selfield-refresh = 'X'.

  case r_ucomm.

    when '&IC1' .

      if rs_selfield-fieldname = 'CRSNR' .
        clear izf18s.
        read table izf18s index  rs_selfield-tabindex.
        perform process_show_zcrse_alv using izf18s-crsnr.
      else.
        perform process_ucomm_ic1 using rs_selfield-tabindex .
      endif.

    when '&SALL' .
      perform process_ucomm_sall.
    when '&DALL' .
      perform process_ucomm_dall.
    when '&EMAIL' .
      perform process_ucomm_email.
    when '&RESEND' .
      perform process_ucomm_resend_email.

    when '&MAINTAIN' .
      perform process_ucomm_maintain_email .

    when '&DELETE' .
      perform process_ucomm_delete .

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
*&      Form  APPENDING_DOWN_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form appending_down_list .
  refresh list.  clear list.

  value-key     = 'ZF18S' .
  value-text    = '销售 绩效表' .
  append value to list.

  call function 'VRM_SET_VALUES'
    exporting
      id     = 'PS_PARM'
      values = list.

  if ps_parm is initial.
    ps_parm = 'ZF18S' .

  endif.

endform.                    " APPENDING_DOWN_LIST
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_UPLOAD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_upload .

  check not p_file is initial.

  perform process_get_execl_data using p_file.

  perform get_izf18s .

  perform show_izf18s .

endform.                    " PROCESS_UCOMM_UPLOAD
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_DOWNLOAD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_download .


  data: gd_webaddr type string.

*http://192.168.88.249:8181/mat_s1.xls
*  gd_webaddr = '\\192.168.88.249\sap\Template_WF\mat_s1.xls'.
  gd_webaddr = 'http://dl.fushiyuan.com.cn/zf18.xlsx'.

  call method cl_gui_frontend_services=>execute
    exporting
      document = gd_webaddr
    exceptions
      others   = 1.

endform.                    " PROCESS_UCOMM_DOWNLOAD
*&---------------------------------------------------------------------*
*&      Form  GET_IZF18S
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_izf18s .

  data p_crsnr like zs42s-crsnr.
  data l_tabix(10) type c.

  read table iexcel index 1.

  if iexcel-value = '年份' .
    delete iexcel where row = '0001' .
  endif.

  loop at iexcel .

    condense iexcel-value.
    shift iexcel-value left deleting leading space .
    if  iexcel-value = '#N/A' .
      iexcel-value = '' .
    endif.

    translate iexcel-value to upper case.
    case iexcel-col.
      when '0001' .
        izf18s-mjahr      = iexcel-value.
      when '0002' .
        izf18s-month_j    = iexcel-value.
      when '0003' .
        izf18s-month_f    = iexcel-value.
      when '0004' .
        izf18s-division   = iexcel-value.
      when '0005' .
        izf18s-sales      = iexcel-value.
      when '0006' .
        izf18s-kpi1       = iexcel-value.
      when '0007' .
        izf18s-kpi2       = iexcel-value.
      when '0008' .
        izf18s-kpi3       = iexcel-value.
      when '0009' .
        izf18s-kpi4       = iexcel-value.
      when '0010' .
        izf18s-kpi5       = iexcel-value.
      when '0011' .
        izf18s-kpi6       = iexcel-value.
      when '0012' .
        izf18s-kpi7       = iexcel-value.
      when '0013' .
        izf18s-kpi8       = iexcel-value.
      when '0014' .
        izf18s-kpi9       = iexcel-value.
      when '0015' .
        izf18s-kpi10       = iexcel-value.
      when '0016' .
        izf18s-bonus1      = iexcel-value.
      when '0017' .
        izf18s-grade1      = iexcel-value.
      when '0018' .
        izf18s-grade2      = iexcel-value.
      when '0019' .
        izf18s-bonus2      = iexcel-value.
      when '0020' .
        izf18s-bonus3      = iexcel-value.
      when '0021' .
        izf18s-bonus4      = iexcel-value.
      when '0022' .
        izf18s-bonus5      = iexcel-value.
      when '0023' .
        izf18s-remark      = iexcel-value.
      when '0024' .
        izf18s-sts1        = iexcel-value.
    endcase.

    at end of row.
      append izf18s . clear izf18s .
    endat.

  endloop.

  check not izf18s[] is initial.

  call function 'NUMBER_GET_NEXT'
    exporting
      nr_range_nr = '32'
      object      = 'ZCRS'
      quantity    = '1'
    importing
      number      = p_crsnr.

  loop at izf18s .

    l_tabix = sy-tabix.
    condense l_tabix .
    concatenate p_crsnr l_tabix into izf18s-seqnum .
    modify izf18s .
  endloop.

  modify zf18s from table izf18s .

endform.                    " GET_IZF18S
*&---------------------------------------------------------------------*
*&      Form  GET_IZS18S_FROM_DB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_izf18s_from_db .

  clear izf18s[] .

  select * from zf18s into corresponding fields of table izf18s
    where mjahr = p_mjahr
      and month_j in s_month
      and month_f in s_monthf
      and sales in s_sales
      and division in s_div .


  if p_nosend = 'X' .
    delete izf18s where email = 'X' .
  endif.


endform.                    " GET_IZS18S_FROM_DB
*&---------------------------------------------------------------------*
*&      Form  SHOW_IZF18S
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form show_izf18s .

  perform initial_alv_layout.

  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZF18'
    tables
      fieldcat = gt_fieldcat[].

  perform get_smtp_addr.

  call function 'REUSE_ALV_GRID_DISPLAY'
    exporting
      i_callback_program       = sy-repid
      is_layout                = gs_layout
*      it_events                = it_event
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      it_fieldcat              = gt_fieldcat[]
      i_save                   = 'C'
    tables
      t_outtab                 = izf18s
    exceptions
      program_error            = 1
      others                   = 2.

endform.                    " SHOW_IZF18S
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_&IC1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_ic1 using p_tabindex.

  read table izf18s index p_tabindex.

  clear c18[] .
  select * from zf18s into corresponding fields of table c18
    where mjahr = p_mjahr
      and sales = izf18s-sales.

  perform initial_alv_layout.

  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZF18'
    tables
      fieldcat = gt_fieldcat[].

  loop at gt_fieldcat where fieldname = 'MONTH_J'.
    gt_fieldcat-seltext_m = p_mjahr .
    modify gt_fieldcat.
  endloop.

  call function 'REUSE_ALV_GRID_DISPLAY'
    exporting
      i_callback_program       = sy-repid
      is_layout                = gs_layout
*      it_events                = it_event
*      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      it_fieldcat              = gt_fieldcat[]
      i_save                   = 'C'
    tables
      t_outtab                 = c18
    exceptions
      program_error            = 1
      others                   = 2.


endform.                    " PROCESS_UCOMM_&IC1
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_SALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_sall .

  loop at izf18s.
    izf18s-sel = 'X' .
    modify izf18s.
  endloop.

endform.                    " PROCESS_UCOMM_SALL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_DALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_dall .

  loop at izf18s.
    izf18s-sel = '' .
    modify izf18s.
  endloop.

endform.                    " PROCESS_UCOMM_DALL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_email .

  data c18 like izf18s occurs 0 with header line.
  data count type i .
  data tabix type i .

  c18[] = izf18s[].
  delete c18 where sel <> 'X' .
  delete c18 where email = 'X' .

  count = lines( c18 ) .
  tabix = 1.

  loop at izf18s where sel = 'X'
                    and email <> 'X' .

    if not izf18s-smtp_addr is initial .

      call function 'ZPRO_PROGRESS_INDICATOR'
        exporting
          tabix = tabix
          lines = count
          text1 = ' 正在发送邮件:'
          text2 = izf18s-sales.

      perform create_crsnr changing p_crsnr .
      perform process_send_email .
      perform update_izf18s .

    endif.

    tabix = tabix + 1.
  endloop.

endform.                    " PROCESS_UCOMM_EMAIL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_SEND_EMAIL_
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_send_email .
  data l_subject(100) type c.
  data l_attfile(100) type c.

  perform appending_izcrs using '{{CRSNR}}' p_crsnr.
  perform appending_izcrs_mail_to_list using izf18s-smtp_addr .
  perform appending_izcrs_mail_to_list using 'yhp@hydronsh.com' .

*  perform appending_izcrs_mail_to_list using 'zhoujun@hydronsh.com' .

  concatenate izf18s-sales ': ' izf18s-mjahr '/' izf18s-month_j '月,业绩考核表' into l_subject .
  perform appending_izcrs using '{{SUBJECT}}'   l_subject .
  perform appending_izcrs using '{{MJAHR}}'   izf18s-mjahr .
  perform appending_izcrs using '{{SALES}}'   izf18s-sales .

  perform get_sales_content .
  perform sync_tables_to_client_300.
  perform send_email_by_python .

endform.                    " PROCESS_SEND_EMAIL_
*&---------------------------------------------------------------------*
*&      Form  CREATE_CRSNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_CRSNR  text
*----------------------------------------------------------------------*
form create_crsnr  changing p_p_crsnr.

  clear p_crsnr .

  call function 'NUMBER_GET_NEXT'
    exporting
      nr_range_nr = '18'
      object      = 'ZCRS'
      quantity    = '1'
    importing
      number      = p_p_crsnr.

endform.                    " CREATE_CRSNR
*&---------------------------------------------------------------------*
*&      Form  GET_SALES_CONTENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_sales_content .

  data l_line type dsvasdvarkeyl.

  data begin of tx.
  data: month_j like zf18s-month_j,
        kpi1 like zf18s-kpi1,
        kpi2 like zf18s-kpi4,
        kpi3 like zf18s-kpi4,
        kpi4 like zf18s-kpi6,
        kpi5 like zf18s-kpi4,
        kpi6 like zf18s-kpi6,
        kpi7 like zf18s-kpi4,
        kpi8 like zf18s-kpi4,
        kpi9 like zf18s-kpi4,
        kpi10 like zf18s-kpi4,
        bonus1(10) type c,
        grade1(3) type c,
        grade2(3) type c,
        bonus2(10) type c,
        bonus3(10) type c,
        bonus4(10) type c,
        bonus5(10) type c,
        remark(60) type c.
  data end of tx.

  select * from zf18s into corresponding fields of zf18s
      where mjahr = izf18s-mjahr
        and month_j <= izf18s-month_j
        and sales = izf18s-sales .

    clear tx.
    move-corresponding zf18s to tx.

    if zf18s-bonus1 is initial.
      tx-bonus1 = ''.
    endif.

    if zf18s-bonus2 is initial.
      tx-bonus2 = ''.
    endif.

    if zf18s-grade1 is initial.
      tx-grade1 = ''.
    endif.

    if zf18s-grade2 is initial.
      tx-grade2 = ''.
    endif.

    if zf18s-bonus3 is initial.
      tx-bonus3 = ''.
    endif.

    if zf18s-bonus4 is initial.
      tx-bonus4 = ''.
    endif.

    if zf18s-bonus5 is initial.
      tx-bonus5 = ''.
    endif.

    if zf18s-kpi10 is initial.
      tx-kpi10 = ''.
    endif.


    concatenate
        tx-month_j
        tx-kpi1
        tx-kpi2
        tx-kpi3
        tx-kpi4
        tx-kpi5
        tx-kpi6
        tx-kpi7
        tx-kpi8
        tx-kpi9
        tx-kpi10
        tx-bonus1
        tx-grade1
        tx-grade2
        tx-bonus2
        tx-bonus3
        tx-bonus4
        tx-bonus5
        tx-remark
    into l_line  separated by '|' .

    perform appending_izcrs using '{{TABLES}}' l_line.

  endselect.

endform.                    " GET_SALES_CONTENT
*&---------------------------------------------------------------------*
*&      Form  UPDATE_IZF18S
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form update_izf18s .

  clear iexec_protocol.
  read table iexec_protocol index 1.

  if iexec_protocol-message = 'SEND' .
    izf18s-email = 'X' .
    izf18s-crsnr = p_crsnr .
    modify izf18s .
    modify zf18s from izf18s .

    call function 'RZL_SLEEP'
      exporting
        seconds = 5.

  else.
    izf18s-crsnr = p_crsnr .
    modify izf18s .

    perform process_append_zcrse  using p_crsnr.
    call function 'RZL_SLEEP'
      exporting
        seconds = 1.

  endif.
endform.                    " UPDATE_IZF18S
*&---------------------------------------------------------------------*
*&      Form  SEND_EMAIL_BY_PYTHON
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form send_email_by_python .

  data p_cmd like sxpgcolist-parameters.

  concatenate p_py p_crsnr into p_cmd separated by space .

  clear  iexec_protocol[].
  call function 'SXPG_CALL_SYSTEM'
    destination p_host
    exporting
      commandname           = 'Z_PYTHON'
      additional_parameters = p_cmd
    tables
      exec_protocol         = iexec_protocol.

endform.                    " SEND_EMAIL_BY_PYTHON
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_MAINTAIN_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_maintain_email .

  data ise16n_seltab like se16n_seltab occurs 0 with header line.


  ise16n_seltab-field   = 'BUKRS' .
  ise16n_seltab-sign    = 'I' .
  ise16n_seltab-option  = 'EQ' .
  ise16n_seltab-low     = 'ZF18' .
  append ise16n_seltab .


  call function 'SE16N_INTERFACE'
    exporting
      i_tab                  = 'ZWF7A'
      i_edit                 = 'X'
      i_sapedit              = 'X'
      i_display              = 'X'
      i_max_lines            = 5000
    tables
      it_selfields           = ise16n_seltab
*     IT_OUTPUT_FIELDS       =
*     IT_OR_SELFIELDS        =
*   EXCEPTIONS
*     NO_VALUES              = 1
*     OTHERS                 = 2
            .
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.

endform.                    " PROCESS_UCOMM_MAINTAIN_EMAIL
*&---------------------------------------------------------------------*
*&      Form  GET_SMTP_ADDR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form get_smtp_addr .

  loop at izf18s .
    select single smtp_addr from zwf7a into izf18s-smtp_addr
      where bukrs = 'ZF18'
        and kunnr = izf18s-sales.

    modify izf18s.
  endloop.

endform.                    " GET_SMTP_ADDR
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_RESEND_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_resend_email .

  data c18 like izf18s occurs 0 with header line.
  data count type i .
  data tabix type i .

  c18[] = izf18s[].
  delete c18 where sel <> 'X' .

  count = lines( c18 ) .
  tabix = 1.

  perform update_izf18s_resend .

  loop at izf18s where sel = 'X' .

    if not izf18s-smtp_addr is initial .


      call function 'ZPRO_PROGRESS_INDICATOR'
        exporting
          tabix = tabix
          lines = count
          text1 = ' 正在发送邮件:'
          text2 = izf18s-sales.

      perform create_crsnr changing p_crsnr .
      perform process_send_email .
      perform update_izf18s .

    endif.

    tabix = tabix + 1.
  endloop.


endform.                    " PROCESS_UCOMM_RESEND_EMAIL
*&---------------------------------------------------------------------*
*&      Form  UPDATE_IZF18S_RESEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form update_izf18s_resend .

  loop at izf18s where sel = 'X' .
    izf18s-email = '' .
    izf18s-crsnr = '' .
    modify izf18s .
  endloop .


endform.                    " UPDATE_IZF18S_RESEND
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_DELETE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_delete .

  data answer(1) type c .

  call function 'POPUP_TO_CONFIRM_WITH_MESSAGE'
    exporting
      diagnosetext1 = '确定对选择项目进行删除？'
      textline1     = ''
      titel         = 'Yes or No'
    importing
      answer        = answer.

  check answer = 'J' .

  clear izf18h[] . clear izf18h .

  loop at izf18s where sel = 'X'.

    move-corresponding izf18s to izf18h .
*    append izf18h . clear izf18h .

    MODIFY zf18h from izf18h .

    delete izf18s .

    delete from zf18s where mjahr   = izf18s-mjahr
                        and month_j = izf18s-month_j
                        and sales   = izf18s-sales
                        and seqnum  = izf18s-seqnum .

  endloop.

endform.                    " PROCESS_UCOMM_DELETE

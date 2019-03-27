*----------------------------------------------------------------------*
* Program Name: ZWF00007
* Project     : N/A
* Author      : Zhou Jun
* Date        : 2018.3
* Module      : N/A
* Description : 对账单自动发送系统
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

report  zwf00007.

include zfuncmu1 .
include zfuncmu2 .
include zfuncmu3 .
include zfuncmu4 .
include zfuncmu5 .

tables zwf7a.
tables zwf7b.
tables zwf7c.
tables adrc.
tables kna1.
tables mara.
tables tbtcp .
tables t880.
tables tsp01.

data sub_dynnr like sy-dynnr .

data zeile like zwf7b-zeile.

data begin of izwf7b occurs 0.
        include structure zwf7b.
data sel like sy-calld.
data end of izwf7b.

data lzwf7b like izwf7b occurs 0 with header line.

controls tc_200  type tableview using screen 0200. "table control的定义
controls tc_300  type tableview using screen 0300. "table control的定义3
controls tc_400  type tableview using screen 0400. "table control的定义3

*constants save_fd(100) type c value '\\192.168.80.249\WF7\ATTFILES\' .
*constants p_py(100)    type c value 'F:\WF7\PY\SEND_WF7.py'.
*constants p_py_horien(100)    type c value 'F:\WF7\PY\SEND_WF7_HORIEN.py'.
*constants p_py_hydron(100)    type c value 'F:\WF7\PY\SEND_WF7_HYDRON.py'.
*constants p_zip(100)   type c value 'F:\WF7\attfiles\ZIP_WF7.py'.
*constants att_fd(100)  type c value 'F:\WF7\ATTFILES\' .
*constants open_fd(100) type c value '\\192.168.88.249\WF7\ATTFILES\' .


constants save_fd(100) type c value '\\192.168.80.249\SAPEDI\WF7\ATTFILES\' .
constants p_py(100)    type c value 'E:\SAPEDI\WF7\PY\SEND_WF7.py'.
constants p_py_horien(100)    type c value 'E:\SAPEDI\WF7\PY\SEND_WF7_HORIEN.py'.
constants p_py_hydron(100)    type c value 'E:\SAPEDI\WF7\PY\SEND_WF7_HYDRON.py'.
constants p_py_fsy(100)       type c value 'E:\SAPEDI\WF7\PY\SEND_WF7_FSY.py'.


constants p_zip(100)   type c value 'E:\SAPEDI\WF7\attfiles\ZIP_WF7.py'.
constants att_fd(100)  type c value 'E:\SAPEDI\WF7\ATTFILES\' .
constants open_fd(100) type c value '\\192.168.80.249\SAPEDI\WF7\ATTFILES\' .

data is_saved like sy-calld.
data is_initial_300 like sy-calld.
data is_checked_200 like sy-calld.

data p_nosend like sy-calld.

data kunnr like zwf7b-kunnr.
data count type i .
data tabix type i .


selection-screen begin of screen 401 as subscreen.
selection-screen begin of block b1 with frame title text-001.
select-options: s_kunnr for kna1-kunnr.
selection-screen end of block b1.
selection-screen end of screen 401.

data ldate like sy-datum.
data ltime like sy-uzeit.
data is_imd like sy-calld value 'X'.
data is_rebulid like sy-calld .

data l_variant_name like lw_varid-variant .
data l_report_name like sy-repid.
data ikna1 like kna1 occurs 0 with header line.

data is_hydron like sy-calld.
data is_horien like sy-calld.

data p_bukrs like zwf7b-bukrs.
data is_initial_999 like sy-calld.

type-pools: vrm.
data: list      type vrm_values,
      value     like line of list,
      name      type vrm_id.

data p_clear_variant like sy-calld.
data p_clear_pdf     like sy-calld.

data izwf7c like zwf7c occurs 0 with header line.

data p_icon(30) type c.
data is_test like sy-calld.
data is_resend like sy-calld.
data is_initial_zwf7_300e like sy-calld.

type-pools sp01r.
data begin of ireq occurs 0.
        include structure tsp01_sp0r.
data:    checkbox(1) type c,
         selected(1) type c,
         deleted(1) type c,
         sindex like sy-tabix,
         color_info type slis_t_specialcol_alv.
data end of ireq.

data answer like sy-calld.

data begin of ierror occurs 0 .
data    crsnr like zcrs-crsnr.
        include structure btcxpm .
data end of ierror.

data ishow_error like ierror occurs 0 with header line.

data it880 like t880 occurs 0 with header line.


start-of-selection.

*  perform initial_date .

  create object g_application.

  call screen 100.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module status_0100 output.
  set pf-status 'S100'.
  set titlebar 'xxx'.

endmodule.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0200 input.

  check is_checked_200 is initial  .

  case sy-ucomm.

    when 'ZWF7_PB1' .
      perform process_ucomm_zwf7_pb1.
    when 'ZWF7_PB2' .
      perform process_ucomm_zwf7_pb2.

  endcase.


endmodule.                 " USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*&      Module  INITIAL_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module initial_0100 output.

  clear sy-ucomm.

  if sub_dynnr is initial .
    sub_dynnr = '999' .
  endif.

  if is_docking_load is initial.

    clear g_ad_tree_nodes[]. clear g_ad_tree_nodes.
    perform appending_g_ad_tree_nodes using 'ROOT'
                                      '0'
                                      'X'
                                      '@9Z@'
                                      '@9Z@'
                                      '电子对账单投递系统'
                                      ''.
    perform append_sub_g_ad_tree_nodes using  'ZWF7' .

    perform create_docking_container_tree tables g_ad_tree_nodes
                                          using '0100'
                                                '' .
    is_docking_load = 'X' .

  endif.

endmodule.                 " INITIAL_0100  OUTPUT

*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_PB1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_pb1 .

  clear p_path.
  clear is_saved.

  call function 'F4_FILENAME'
    importing
      file_name = p_path.

endform.                    " PROCESS_UCOMM_ZWF7_PB1
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_PB2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_pb2 .

  data stripped_name type string.
  data file_path      type string.

  data long_filename  like dbmsgora-filename.
  data pure_filename  like sdbah-actid.
  data pure_extension like sdbad-funct.

  data s_message_text(100) type c.
  data l_kunnr like zwf7b-kunnr.

  check not p_path is initial.

  check is_saved is initial.

  clear izwf7b[] .   clear izwf7b .

  call function 'SO_SPLIT_FILE_AND_PATH'
    exporting
      full_name     = p_path
    importing
      stripped_name = stripped_name
      file_path     = file_path.

*  long_filename = stripped_name .
*
*  call function 'SPLIT_FILENAME'
*    exporting
*      long_filename  = long_filename
*    importing
*      pure_filename  = pure_filename
*      pure_extension = pure_extension.

  if not pure_extension = 'PDF' .

  endif.

  perform get_docsn using     stripped_name
                    changing  zwf7b-docsn .


  perform copy_file_to_remote_server using p_path
                                           zwf7b-docsn .

*  perform get_zeile changing zwf7b-zeile .

  perform check_is_send_seleced using stripped_name .

  if sy-subrc = 0.
    is_saved = 'X' .

    call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
      exporting
        input  = izwf7b-kunnr
      importing
        output = l_kunnr.


    concatenate l_kunnr zwf7b-mjahr zwf7b-monnm '上传成功！' into s_message_text separated by space.
    message i003(z1) with s_message_text.

  endif.


endform.                    " PROCESS_UCOMM_ZWF7_PB2
*&---------------------------------------------------------------------*
*&      Form  GET_ZEILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_ZEILE  text
*----------------------------------------------------------------------*
form get_zeile  changing zeile.

  clear zeile.

  sort izwf7b by zeile descending.
  read table izwf7b index 1.

  zeile = izwf7b-zeile + 1.

  sort izwf7b .

endform.                    " GET_ZEILE
*&---------------------------------------------------------------------*
*&      Form  GET_DOCSN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_ZWF7B_DOCSN  text
*----------------------------------------------------------------------*
form get_docsn  using  p_pure_extension
                 changing p_zwf7b_docsn.

  data short_name(10) type c.

  call function 'NUMBER_GET_NEXT'
    exporting
      nr_range_nr = '80'
      object      = 'ZCRS'
      quantity    = '1'
    importing
      number      = short_name.

  concatenate short_name p_pure_extension into p_zwf7b_docsn .

endform.                    " GET_DOCSN
*&---------------------------------------------------------------------*
*&      Module  INITIAL_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module initial_0200 output.

  perform initial_date .

endmodule.                 " INITIAL_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  COPY_FILE_TO_REMOTE_SERVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_PATH  text
*      -->P_ZWF7B_DOCSN  text
*----------------------------------------------------------------------*
form copy_file_to_remote_server  using    p_p_path
                                          p_zwf7b_docsn.

  data i_file_front_end   type string .
  data i_file_appl        like rcgfiletr-ftappl .

  i_file_front_end  = p_p_path.

  concatenate save_fd p_zwf7b_docsn into i_file_appl.

  call function 'C13Z_FILE_UPLOAD_BINARY'
   exporting
     i_file_front_end          = i_file_front_end
     i_file_appl               = i_file_appl
*    I_FILE_OVERWRITE          = 'X'
* IMPORTING
*   E_FLG_OPEN_ERROR          =
*   E_OS_MESSAGE              =
* EXCEPTIONS
*   FE_FILE_OPEN_ERROR        = 1
*   FE_FILE_EXISTS            = 2
*   FE_FILE_WRITE_ERROR       = 3
*   AP_NO_AUTHORITY           = 4
*   AP_FILE_OPEN_ERROR        = 5
*   AP_FILE_EMPTY             = 6
*   OTHERS                    = 7
           .
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

endform.                    " COPY_FILE_TO_REMOTE_SERVER
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0100 input.


  call method cl_gui_cfw=>dispatch
    importing
      return_code = return_code.


  check not p_node_key is initial.


  case p_node_key .
    when 'ROOT' .
      sub_dynnr = '999' .

    when 'ZWF7_HN1' .

      call transaction 'ZWF7HN1' .

    when others.
      read table izwfs1 with key node_key = p_node_key.
      if sy-subrc = 0 .
        if izwfs1-action = 'ZWF7A'.
          sub_dynnr = '500' .
*          perform process_ucomm_zwf7a.
        else.
          sub_dynnr = izwfs1-action .

          if sub_dynnr = '300'.

            clear zwf7b-monnm.
            clear izwf7b[].
            clear izwf7b  .
          endif.
        endif.

*      call transaction izwfs1-action .
        clear sy-ucomm.
        clear p_node_key.

      endif.

  endcase.


endmodule.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  RELOAD_IZWF7B  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module reload_izwf7b input.
*  perform reload_izwf7b .

  perform process_ucomm_zwf7_l300. .

endmodule.                 " RELOAD_IZWF7B  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0300 input.


  case sy-ucomm.
    when 'ZWF7_L300' .
*      perform reload_izwf7b .

      perform process_ucomm_zwf7_l300. .
    when 'SEL_ALL' .
      perform process_ucomm_sel_all.
    when 'DESEL_ALL' .
      perform process_ucomm_desel_all.
    when 'ZWF7_PB3' .
      perform process_ucomm_zwf7_pb3 using 'X'.
    when 'ZWF7_PB4' .

      call function 'POPUP_TO_CONFIRM'
        exporting
          text_question = '确认进行全部发送？'
        importing
          answer        = answer.

      check answer = '1' .

      perform process_ucomm_zwf7_pb3 using '' .
    when 'ZWF7_NOSEND' .
      perform process_ucomm_zwf7_no_send.
    when 'DCLICK' .
      perform process_ucomm_dbclick using tc_300-top_line.
    when 'ZWF7_300E' .
      perform process_ucomm_zwf7_300e using  tc_300-top_line.

  endcase.

*  clear sy-ucomm.

endmodule.                 " USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*&      Form  RELOAD_IZWF7B
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form reload_izwf7b .

  clear izwf7b[] . clear izwf7b.

  select * from zwf7b into corresponding fields of table izwf7b
    where bukrs = p_bukrs
      and mjahr = zwf7b-mjahr
      and monnm = zwf7b-monnm .

endform.                    " RELOAD_IZWF7B
*&---------------------------------------------------------------------*
*&      Module  INITIAL_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module initial_0300 output.

*  if izwf7b[] is initial.
*    perform reload_izwf7b .
*  endif.

*  if is_initial_300 is initial.
*
*    clear zwf7b-monnm.
*    is_initial_300 = 'X' .
*
*  endif.

  perform initial_date .

  if izwf7b[] is initial.
    perform reload_izwf7b .
  endif.

  if p_nosend = 'X' .
    delete izwf7b where is_send <> '' .
  endif.

  delete izwf7b where docsn is initial.

  describe table izwf7b lines tc_300-lines.

endmodule.                 " INITIAL_0300  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_SEL_ALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_sel_all .

  loop at izwf7b.
    izwf7b-sel = 'X' .
    modify izwf7b.
  endloop.

endform.                    " PROCESS_UCOMM_SEL_ALL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_DESEL_ALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_desel_all .

  loop at izwf7b.
    izwf7b-sel = '' .
    modify izwf7b.
  endloop.

endform.                    " PROCESS_UCOMM_DESEL_ALL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_PB3
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_pb3 using p_sel .

  data l_kunnr like zwf7b-kunnr.

  clear ierror[] . clear ierror.

  perform get_progress_indicator_count using p_sel
                                       changing count.
  tabix = 1.

  loop at izwf7b  .

*    check izwf7b-is_send is initial.

    call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
      exporting
        input  = izwf7b-kunnr
      importing
        output = l_kunnr.

    call function 'ZPRO_PROGRESS_INDICATOR'
      exporting
        tabix = tabix
        lines = count
        text1 = ' 正在发送客户邮件:'
        text2 = l_kunnr.

    perform process_send_email_by_kunnr .


    tabix = tabix + 1.
  endloop.
*  perform excute_python_command using p_send '' '' .

  perform reload_izwf7b .

endform.                    " PROCESS_UCOMM_ZWF7_PB3
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7A
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7a .


  call function 'VIEW_MAINTENANCE_CALL'
    exporting
      action    = 'U'
      view_name = 'ZWF7A'.

endform.                    " PROCESS_UCOMM_ZWF7A
*&---------------------------------------------------------------------*
*&      Module  MODIFY_IZWF7B_TC_300_PAI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module modify_izwf7b_tc_300_pai input.

*  read table izwf7b index tc_300-current_line.

  call function 'CONVERSION_EXIT_ALPHA_INPUT'
    exporting
      input  = izwf7b-kunnr
    importing
      output = izwf7b-kunnr.

  check not izwf7b-kunnr is initial.

  modify izwf7b index tc_300-current_line transporting kunnr sel.

endmodule.                 " MODIFY_IZWF7B_TC_300_PAI  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_SEND_EMAIL_BY_KUNNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IZWF7B_KUNNR  text
*----------------------------------------------------------------------*
form process_send_email_by_kunnr .

  data l_subject(100) type c.
  data l_attfile(100) type c.
  data sdate(10) type c.
  data l_kunnr like kna1-kunnr.
  data name1 like adrc-name1.


  clear zwf7a .

  select single smtp_addr from zwf7a into zwf7a-smtp_addr
    where bukrs = p_bukrs
      and kunnr = izwf7b-kunnr .

  if is_test = 'X' .
    zwf7a-smtp_addr = 'notice@hydronsh.com,daizhiqing@hydronsh.com,horien-dzd@hydronsh.com' .
  endif.

  check not zwf7a-smtp_addr is initial.

  clear p_crsnr .
  clear p_crsnp .
  clear izcrs[] .

  call function 'NUMBER_GET_NEXT'
    exporting
      nr_range_nr = '81'
      object      = 'ZCRS'
      quantity    = '1'
    importing
      number      = p_crsnr.

  perform appending_izcrs using '{{CRSNR}}'     p_crsnr.

  perform process_append_to_list using zwf7a-smtp_addr .

  if is_test is initial .
    perform process_append_regular_list.
  endif.

  call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
    exporting
      input  = izwf7b-kunnr
    importing
      output = l_kunnr.

  case p_bukrs.
    when 'HS00' or 'QL00' .
      concatenate '海昌隐形眼镜客户(' l_kunnr ') ' izwf7b-mjahr '年' izwf7b-monnm '月对账单' into l_subject .

      perform appending_izcrs using '{{TO_LIST}}' 'daizhiqing@hydronsh.com' .

    when 'HN00' .
      concatenate '海俪恩隐形眼镜客户(' l_kunnr ') ' izwf7b-mjahr '年' izwf7b-monnm '月对账单' into l_subject .
      perform appending_izcrs using '{{TO_LIST}}' 'zhouxiaoyan@hydronsh.net' .
    when 'FS00' .
      concatenate '富视远隐形眼镜客户(' l_kunnr ') ' izwf7b-mjahr '年' izwf7b-monnm '月对账单' into l_subject .

  endcase.

  perform appending_izcrs using '{{SUBJECT}}'   l_subject .

  concatenate att_fd izwf7b-docsn into l_attfile .

  perform appending_izcrs using '{{ATTFILE}}'   l_attfile .

  perform convert_date_to_text(zsd00006) using sy-datum '-'
                                         changing sdate.

  perform appending_izcrs using '{{SDATE}}' sdate .

  perform appending_izcrs using '{{MJAHR}}' izwf7b-mjahr .

  perform appending_izcrs using '{{MONNM}}' izwf7b-monnm .

  call function 'ZPRO_GET_CUSTOMER_LONG_NAME'
    exporting
      kunnr = izwf7b-kunnr
    importing
      name  = name1.

  perform appending_izcrs using '{{KUNNR}}' name1 .


  perform sync_tables_to_client_300.


  case p_bukrs .
    when 'HS00' or 'QL00' .
      perform excute_python_command using p_py_hydron p_crsnr '' .
    when 'HN00' .
      perform excute_python_command using p_py_horien p_crsnr '' .
    when 'FS00' .
      perform excute_python_command using p_py_fsy p_crsnr '' .
  endcase.

  perform process_update_status_zwf7b .

endform.                    " PROCESS_SEND_EMAIL_BY_KUNNR
*&---------------------------------------------------------------------*
*&      Form  PROCESS_APPEND_TO_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ZWF7A_SMTP_ADDR  text
*----------------------------------------------------------------------*
form process_append_to_list  using    p_zwf7a_smtp_addr.

  data l_add1 like zwf7a-smtp_addr .
  data l_add2 like zwf7a-smtp_addr .
  data l_add  like zwf7a-smtp_addr .

  l_add = p_zwf7a_smtp_addr.

  do.
    split l_add at ',' into l_add1 l_add2.

    if not l_add1 is initial.
      perform appending_izcrs using '{{TO_LIST}}' l_add1 .
    endif.

    if l_add2 is initial.
      exit.
    endif.

    l_add = l_add2 .

  enddo.


endform.                    " PROCESS_APPEND_TO_LIST
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_NO_SEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_no_send .

  perform reload_izwf7b .

  if p_nosend = 'X' .
    delete izwf7b where is_send <> '' .
  endif.
endform.                    " PROCESS_UCOMM_ZWF7_NO_SEND
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UPDATE_STATUS_ZWF7B
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_update_status_zwf7b .

  read table iexec_protocol index 1.

  if iexec_protocol-message = 'SEND' .
    izwf7b-is_send = 'X' .
    izwf7b-sddat   = sy-datum.
    izwf7b-sdnam   = sy-uname.
    izwf7b-crsnr   = p_crsnr .

    modify izwf7b.
    modify zwf7b from izwf7b.
    clear izwf7b .

    call function 'RZL_SLEEP'
      exporting
        seconds = 5.

  else.
    message s003(z1) with izwf7b-kunnr '|' izwf7b-monnm '邮件发送失败.' .

    izwf7b-crsnr   = p_crsnr .

    modify izwf7b.
    if is_test is initial .
      modify zwf7b from izwf7b.
    endif.
    perform process_append_ierrors using p_crsnr.
    perform process_append_zcrse  using p_crsnr.

*   append lines of iexec_protocol to ierror .
    call function 'RZL_SLEEP'
      exporting
        seconds = 1.

  endif.

endform.                    " PROCESS_UPDATE_STATUS_ZWF7B
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_0300_PBO  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module display_0300_pbo output.


  call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
    exporting
      input  = izwf7b-kunnr
    importing
      output = izwf7b-kunnr.

*  izwf7b-icon = 'ICON_SEARCH' .


  if izwf7b-is_send is initial.

    call function 'ICON_CREATE'
      exporting
        name                  = 'ICON_LED_YELLOW'
      importing
        result                = p_icon
      exceptions
        icon_not_found        = 1
        outputfield_too_short = 2
        others                = 3.

  else.

    call function 'ICON_CREATE'
      exporting
        name                  = 'ICON_LED_GREEN'
      importing
        result                = p_icon
      exceptions
        icon_not_found        = 1
        outputfield_too_short = 2
        others                = 3.
  endif.

endmodule.                 " DISPLAY_0300_PBO  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_CHECK_KUNNR_EXIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ZWF7B_KUNNR  text
*----------------------------------------------------------------------*
form process_check_kunnr_exist  using    p_zwf7b_kunnr.

  select single * from kna1 where kunnr = p_zwf7b_kunnr.

  if sy-subrc = 0 .

*    select * from zwf7b into corresponding fields of table izwf7b
*      where bukrs = p_bukrs
*        and kunnr = zwf7b-kunnr
*        and mjahr = zwf7b-mjahr
*        and monnm = zwf7b-monnm.

    clear adrc-name1.
    call function 'ZPRO_GET_CUSTOMER_LONG_NAME'
      exporting
        kunnr = p_zwf7b_kunnr
      importing
        name  = adrc-name1.
  else.
    is_checked_200 = 'X' .
    message i003(z1) with '客户' p_zwf7b_kunnr '不存在！'.
    call screen 100.
  endif.

endform.                    " PROCESS_CHECK_KUNNR_EXIST
*&---------------------------------------------------------------------*
*&      Form  PROCESS_CHECK_KUNNR_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ZWF7B_KUNNR  text
*----------------------------------------------------------------------*
form process_check_kunnr_email  using    p_zwf7b_kunnr.

  select single * from zwf7a where bukrs = p_bukrs and kunnr = p_zwf7b_kunnr.

  if sy-subrc = 0 .

  else.
    is_checked_200 = 'X' .
    message i003(z1) with '客户邮箱' p_zwf7b_kunnr '没有维护,请先维护！'.
    call screen 100.
  endif.

endform.                    " PROCESS_CHECK_KUNNR_EMAIL
*&---------------------------------------------------------------------*
*&      Form  GET_PROGRESS_INDICATOR_COUNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0647   text
*      <--P_COUNT  text
*----------------------------------------------------------------------*
form get_progress_indicator_count  using    value(p_0647)
                                   changing p_count.

  clear p_count.
  clear lzwf7b[].

  lzwf7b[] = izwf7b[].

  if p_0647 = 'X' .
    delete lzwf7b where sel <> 'X'  .
  endif.

  if sy-uname = 'C0029' or is_resend = 'X'.

  else.
    delete lzwf7b where is_send = 'X' .
  endif.

  clear izwf7b[].
  izwf7b[] = lzwf7b[] .

  p_count = lines( lzwf7b ) .

endform.                    " GET_PROGRESS_INDICATOR_COUNT
*&---------------------------------------------------------------------*
*&      Module  PAI_200_IS_SAVED  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module pai_200_is_saved input.

  clear is_saved.

endmodule.                 " PAI_200_IS_SAVED  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_L300
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_l300 .


  call function 'CONVERSION_EXIT_ALPHA_INPUT'
    exporting
      input  = zwf7b-monnm
    importing
      output = zwf7b-monnm.



  if zwf7b-monnm is initial.
    clear izwf7b[] . clear izwf7b.
    select * from zwf7b into corresponding fields of table izwf7b
      where bukrs = p_bukrs
        and mjahr = zwf7b-mjahr .

  else.
    perform reload_izwf7b .

  endif.

endform.                    " PROCESS_UCOMM_ZWF7_L300
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_PB4
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_pb4 .

endform.                    " PROCESS_UCOMM_ZWF7_PB4
*&---------------------------------------------------------------------*
*&      Form  CHECK_IS_SEND_SELECED
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form check_is_send_seleced using p_stripped_name.

  data l_zwf7b like zwf7b occurs  0 with header line .


  zwf7b-bukrs = p_bukrs.
  zwf7b-zeile = '' .
  zwf7b-erdat = sy-datum.
  zwf7b-ernam = sy-uname.
  zwf7b-docfn = p_stripped_name.
  zwf7b-jobstatus = 'F'.

  clear l_zwf7b.
  select single * from zwf7b into corresponding fields of l_zwf7b
    where bukrs = p_bukrs
      and kunnr = zwf7b-kunnr
      and mjahr = zwf7b-mjahr
      and monnm = zwf7b-monnm.

  if sy-subrc = 0 and l_zwf7b-is_send is initial.
    move-corresponding zwf7b to izwf7b .
    append izwf7b.
    modify zwf7b from izwf7b.
  else.
    move-corresponding zwf7b to izwf7b .
    append izwf7b.
    modify zwf7b from izwf7b.
  endif.

endform.                    " CHECK_IS_SEND_SELECED
*&---------------------------------------------------------------------*
*&      Module  PAI_200_RELOAD_ZWF7B  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module pai_200_reload_zwf7b input.

  perform reload_izwf7b_by_kunnr.

endmodule.                 " PAI_200_RELOAD_ZWF7B  INPUT
*&---------------------------------------------------------------------*
*&      Form  RELOAD_IZWF7B_BY_KUNNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form reload_izwf7b_by_kunnr .

  clear izwf7b[] . clear izwf7b.

  select * from zwf7b into corresponding fields of table izwf7b
    where bukrs = p_bukrs
      and kunnr = zwf7b-kunnr
      and mjahr = zwf7b-mjahr
      and monnm = zwf7b-monnm.

endform.                    " RELOAD_IZWF7B_BY_KUNNR
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_DBCLICK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_dbclick using top_line .

  data c_line type i.
  data l_fn type so_text255 .

  get cursor line c_line.

  c_line = c_line + top_line - 1.

  read table izwf7b index c_line.

  if sy-subrc = 0 .
    concatenate open_fd izwf7b-docsn into l_fn.
  endif.

  check not l_fn is initial.

  call function 'CALL_INTERNET_ADRESS'
   exporting
     pi_adress           = l_fn
*     PI_TECHKEY          =
*   EXCEPTIONS
*     NO_INPUT_DATA       = 1
*     OTHERS              = 2
            .
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.


endform.                    " PROCESS_UCOMM_DBCLICK
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0400 input.

  case sy-ucomm.
    when 'ZWF7_PDF1' .
      perform process_ucomm_zwf7_pdf1.
    when 'ZWF7_PDF2' .
      perform process_ucomm_zwf7_pdf2.
    when 'DCLICK' .
      perform process_ucomm_dbclick using tc_400-top_line .
  endcase.

endmodule.                 " USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_PDF1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_pdf1 .

  check not s_kunnr is initial.

  clear ikna1[] .
  select * from  kna1 into corresponding fields of table ikna1
    where kunnr in s_kunnr.

  clear izwf7b[] .clear izwf7b.

  count = lines( ikna1 ) .
  tabix = 1 .

  loop at ikna1.

    clear mu3_jobcount.

    select single * from zwf7b into corresponding fields of izwf7b
      where bukrs = p_bukrs
        and kunnr = ikna1-kunnr
        and mjahr = zwf7b-mjahr
        and monnm = zwf7b-monnm.

    perform process_get_report_name changing  l_report_name .


    if is_rebulid = 'X'.

*      check izwf7b-is_send is initial.

      perform process_background_job .
      clear: izwf7b-docsn , izwf7b-spoolid.

      izwf7b-is_send   = '' .
      izwf7b-jobstatus = 'R' .
      izwf7b-jobname = l_variant_name .
      izwf7b-jobcount = mu3_jobcount  .
      izwf7b-docfn = '' .
      izwf7b-docsn = '' .
      izwf7b-crsnr = '' .
      izwf7b-erdat = sy-datum .
      izwf7b-ernam = sy-uname .

      izwf7b-bukrs = p_bukrs.
      izwf7b-kunnr = ikna1-kunnr .
      izwf7b-mjahr = zwf7b-mjahr .
      izwf7b-monnm = zwf7b-monnm .

      modify zwf7b from izwf7b.

    else.
      check izwf7b-is_send is initial.
      perform process_background_job .

      izwf7b-bukrs = p_bukrs.
      izwf7b-kunnr = ikna1-kunnr .
      izwf7b-mjahr = zwf7b-mjahr .
      izwf7b-monnm = zwf7b-monnm .
      izwf7b-erdat = sy-datum .
      izwf7b-ernam = sy-uname .

      izwf7b-jobstatus = 'R' .
      izwf7b-jobname = l_variant_name .
      izwf7b-jobcount = mu3_jobcount  .
      modify zwf7b from izwf7b.

    endif.

    call function 'ZPRO_PROGRESS_INDICATOR'
      exporting
        tabix = tabix
        lines = count
        text1 = ' 正在生产后台JOB:'
        text2 = l_variant_name.

    tabix = tabix + 1 .

    append izwf7b . clear izwf7b .

  endloop.

  commit work and wait.

endform.                    " PROCESS_UCOMM_ZWF7_PDF1
*&---------------------------------------------------------------------*
*&      Form  FULL_OF_LW_VAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form full_of_lw_val using p_kunnr .


  if l_report_name = 'ZSD00038' .
    case p_bukrs .
      when 'HS00' .
        perform process_lw_val_hs00_x1 using p_kunnr.
      when 'HN00' .
        perform process_lw_val_hn00_x1 using p_kunnr.
      when 'FS00' .
        perform process_lw_val_fs00_x1 using p_kunnr.

    endcase.
  else.
    case p_bukrs .
      when 'HS00' .
        perform process_lw_val_hs00 using p_kunnr.
      when 'HN00' .
        perform process_lw_val_hn00 using p_kunnr.
      when 'QL00' .
        perform process_lw_val_ql00 using p_kunnr.
      when 'FS00' .
        perform process_lw_val_fs00 using p_kunnr.
    endcase.

  endif.

endform.                    " FULL_OF_LW_VAL
*&---------------------------------------------------------------------*
*&      Form  FULL_OF_VARIANT_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IKNA1_KUNNR  text
*      <--P_L_VARIANT_NAME  text
*----------------------------------------------------------------------*
form full_of_variant_name  using   p_ikna1_kunnr
                                   p_report_name
                           changing p_l_variant_name.

  data l_kunnr like kna1-kunnr.
  data is_variant_exist like sy-subrc.
  data j1 type i .
  data t1(5) type c.


  call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
    exporting
      input  = p_ikna1_kunnr
    importing
      output = l_kunnr.


  do .
    clear p_l_variant_name .
    clear is_variant_exist .

    call function 'QF05_RANDOM_INTEGER'
      exporting
        ran_int_max = 99999
        ran_int_min = 1
      importing
        ran_int     = j1.

    t1 = j1 . condense t1 .

*    concatenate 'W7' l_kunnr t1 into p_l_variant_name separated by '_'.
    concatenate l_kunnr t1 into p_l_variant_name separated by '_'.
    call function 'RS_VARIANT_EXISTS'
      exporting
        report  = p_report_name
        variant = p_l_variant_name
      importing
        r_c     = is_variant_exist.

    if is_variant_exist <> 0 .
      exit .
    endif.
  enddo.


endform.                    " FULL_OF_VARIANT_NAME
*&---------------------------------------------------------------------*
*&      Form  PROCESS_BACKGROUND_JOB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_background_job .

  clear l_variant_name.
  clear mu3_jobcount.

  perform full_of_variant_name using ikna1-kunnr l_report_name
                               changing l_variant_name .

  perform full_of_lw_val using ikna1-kunnr .

  perform create_variant using l_report_name l_variant_name l_variant_name 'B'  .


  perform create_background_job using l_variant_name
                                      l_report_name
                                      l_variant_name
                                changing mu3_jobcount .

*  perform delete_variant using l_report_name l_variant_name .


endform.                    " PROCESS_BACKGROUND_JOB
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_PDF2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_pdf2 .

  commit work and wait.

  clear izwf7b[] . clear izwf7b.
  clear izwf7c[] . clear izwf7c.


  select * from zwf7b into corresponding fields of table izwf7b
    where bukrs = p_bukrs
      and kunnr in s_kunnr
      and mjahr = zwf7b-mjahr
      and monnm = zwf7b-monnm
      and is_send = ''
      and jobstatus = 'R' .

*  perform process_checking_zwf7c .

  perform process_generate_pdf .

  perform reload_izwf7b_in_kunnr .

endform.                    " PROCESS_UCOMM_ZWF7_PDF2
*&---------------------------------------------------------------------*
*&      Form  PROCESS_GENERATE_PDF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_generate_pdf .


  data l_status like tbtcjob-status .
  data l_spoolid like zwf7b-spoolid .
  data l_pdf_file_name like zwf7b-docsn.
  data zwf7c_status like sy-calld.
  data l_tsp01 like tsp01.
  data errors type ref to cx_sy_arithmetic_error.


  count = lines( izwf7b ) .
  tabix = 1 .

  loop at izwf7b.

    clear l_status  .


    call function 'BP_JOB_STATUS_GET'
      exporting
        jobcount = izwf7b-jobcount
        jobname  = izwf7b-jobname
      importing
        status   = l_status.

    call function 'ZPRO_PROGRESS_INDICATOR'
      exporting
        tabix = tabix
        lines = count
        text1 = ' 正在刷新后台JOB:'
        text2 = izwf7b-jobname.

    tabix = tabix + 1 .

    if l_status = 'F' .

      perform process_checking_zwf7c changing zwf7c_status.

      check zwf7c_status = 'Y' .

      clear l_spoolid .
      call function 'ZPRO_GET_SPOOL_ID'
        exporting
          jobcount        = izwf7b-jobcount
          jobname         = izwf7b-jobname
*         STEPCOUNT       =
       importing
          spoolid         = l_spoolid   .

      select single * from tsp01 where rqident = l_spoolid .

      if sy-subrc = 0.

*        try.
        perform process_create_pdf_file using l_spoolid
                                        changing l_pdf_file_name .
*          catch cx_sy_arithmetic_error into errors.
*            sy-subrc = 4 .
*
*        endtry.
        if sy-subrc = 0 .
          perform process_update_zwf7b using l_status l_spoolid l_pdf_file_name .

          perform process_delete_spool using l_spoolid .
        endif.

      endif.

    elseif l_status = 'P' .
      perform release_job using izwf7b-jobcount  izwf7b-jobname .
    endif.

  endloop.


  perform procsss_delete_zwf7b_by_izwf7c.


endform.                    " PROCESS_GENERATE_PDF

*&---------------------------------------------------------------------*
*&      Form  PROCESS_CREATE_PDF_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SPOOLID  text
*      <--P_L_PDF_FILE_NAME  text
*----------------------------------------------------------------------*
form process_create_pdf_file  using    p_l_spoolid
                              changing p_l_pdf_file_name.

  data ipdf like tline occurs 0 with header line.
  data l_path type string.
  data l_spoolid like tsp01-rqident.
  data l_dname(100) type c.

  check not p_l_spoolid is initial.

  clear ipdf[] .

*  clear p_l_pdf_file_name .

  l_spoolid = p_l_spoolid .

  call function 'CONVERT_ABAPSPOOLJOB_2_PDF'
    exporting
      src_spoolid = l_spoolid
    tables
      pdf         = ipdf.

  perform get_docsn using   '.PDF'
                  changing  p_l_pdf_file_name .

  concatenate save_fd p_l_pdf_file_name into l_path.


  open dataset l_path for output in binary mode .

  if sy-subrc = 0.
    loop at ipdf .
      transfer ipdf to l_path.
    endloop.
    close dataset l_path.
    sy-subrc = 0.

*    concatenate att_fd p_l_pdf_file_name into l_dname .
*    perform excute_python_command using p_zip l_dname '' .
*    concatenate p_l_pdf_file_name '.ZIP' into p_l_pdf_file_name .

  else.
    clear p_l_pdf_file_name.
  endif.

endform.                    " PROCESS_CREATE_PDF_FILE
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UPDATE_ZWF7B
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SPOOLID  text
*      -->P_L_PDF_FILE_NAME  text
*----------------------------------------------------------------------*
form process_update_zwf7b  using   p_l_status
                                    p_l_spoolid
                                    p_l_pdf_file_name.

  check not p_l_spoolid is initial.
  check not p_l_pdf_file_name is initial.

  izwf7b-jobstatus    = p_l_status.
  izwf7b-spoolid      = p_l_spoolid.
  izwf7b-docsn        = p_l_pdf_file_name.

  modify  izwf7b .

  modify zwf7b from izwf7b .
  commit work and wait.

endform.                    " PROCESS_UPDATE_ZWF7B
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_0400_PBO  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module display_0400_pbo output.

  call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
    exporting
      input  = izwf7b-kunnr
    importing
      output = izwf7b-kunnr.


  check not izwf7b-jobstatus is initial.

  if izwf7b-jobstatus = 'R'.

    call function 'ICON_CREATE'
      exporting
        name                  = 'ICON_LED_YELLOW'
      importing
        result                = p_icon
      exceptions
        icon_not_found        = 1
        outputfield_too_short = 2
        others                = 3.

  elseif izwf7b-jobstatus = 'F'..

    call function 'ICON_CREATE'
      exporting
        name                  = 'ICON_LED_GREEN'
      importing
        result                = p_icon
      exceptions
        icon_not_found        = 1
        outputfield_too_short = 2
        others                = 3.

  else.

    call function 'ICON_CREATE'
      exporting
        name                  = 'ICON_LED_RED'
      importing
        result                = p_icon
      exceptions
        icon_not_found        = 1
        outputfield_too_short = 2
        others                = 3.


  endif.




endmodule.                 " DISPLAY_0400_PBO  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  MODIFY_IZWF7B_TC_400_PAI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module modify_izwf7b_tc_400_pai input.

  call function 'CONVERSION_EXIT_ALPHA_INPUT'
    exporting
      input  = izwf7b-kunnr
    importing
      output = izwf7b-kunnr.

  modify izwf7b index tc_400-current_line transporting kunnr.

endmodule.                 " MODIFY_IZWF7B_TC_400_PAI  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_GET_REPORT_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_REPORT_NAME  text
*----------------------------------------------------------------------*
form process_get_report_name  changing p_l_report_name.

  tables knvv .

  clear p_l_report_name.

  p_l_report_name = 'ZSD00038'.


*  select single vkbur into knvv-vkbur from knvv
*    where kunnr = ikna1-kunnr
*      and vkorg = p_bukrs
*      and vkbur = '0007' .
*
*  if sy-subrc = 0 .
*    p_l_report_name = 'ZSD00038'.
*  else.
*    case p_bukrs .
*      when 'HS00' or 'QL00' or 'FS00'.
*        p_l_report_name = 'ZSDR_CUSTCHECK_720_2'.
*      when 'HN00' .
*        p_l_report_name = 'ZSDR_HLN_CUSTCHECK_720_2'.
*    endcase.
*  endif.

endform.                    " PROCESS_GET_REPORT_NAME
*&---------------------------------------------------------------------*
*&      Module  SHOW_WELCOME  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module show_welcome output.


  check is_picture_load is initial.

  perform create_pic_container_mime using 'PICTURE_CONTAINER'
                                      'ZWF7_WELCOME'
                                      'X' .

endmodule.                 " SHOW_WELCOME  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  INITIAL_0400  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module initial_0400 output.

  perform initial_date .

  if izwf7b[] is initial.
    perform reload_izwf7b_in_kunnr .
  endif.

  describe table izwf7b lines tc_400-lines.

endmodule.                 " INITIAL_0400  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  INITIAL_DATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form initial_date .

  if zwf7b-mjahr is initial.
    zwf7b-mjahr = sy-datum(4) .
  endif.

  if zwf7b-monnm is initial.
    zwf7b-monnm = sy-datum+4(2)  .
  endif.

endform.                    " INITIAL_DATE
*&---------------------------------------------------------------------*
*&      Form  RELEASE_JOB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IZWF7B_JOBCOUNT  text
*      -->P_IZWF7B_JOBNAME  text
*----------------------------------------------------------------------*
form release_job  using    p_izwf7b_jobcount
                           p_izwf7b_jobname.

  call function 'JOB_CLOSE'  "Release 这个Job
    exporting
      jobcount             = p_izwf7b_jobcount
      jobname              = p_izwf7b_jobname
      strtimmed            = 'X'
*      sdlstrtdt            = sy-datum
*      sdlstrttm            = sy-uzeit
    exceptions
      cant_start_immediate = 1
      invalid_startdate    = 2
      jobname_missing      = 3
      job_close_failed     = 4
      job_nosteps          = 5
      job_notex            = 6
      lock_failed          = 7
      others               = 8.

endform.                    " RELEASE_JOB
*&---------------------------------------------------------------------*
*&      Module  INITIAL_0999  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module initial_0999 output.


  check is_initial_999 is initial.

  clear list[] .

  value-key  = 'HS00'.
  value-text = '海昌'.
  append value to list.

  value-key  = 'HN00'.
  value-text = '海俪恩'.
  append value to list.

  value-key  = 'FS00'.
  value-text = '富视远'.
  append value to list.

  value-key  = 'QL00'.
  value-text = '全能'.
  append value to list.

  call function 'VRM_SET_VALUES'
    exporting
      id     = 'P_BUKRS'
      values = list.

  is_initial_999 = 'X' .
  if p_bukrs is initial.
    p_bukrs = 'HS00' .
  endif.

  select * from t880 into corresponding fields of table it880 .

  it880-rcomp = 'QL00' .
  it880-name1 = '全能眼镜' .
  append it880 . clear it880 .


endmodule.                 " INITIAL_0999  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_HS00
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_lw_val_hs00 using p_kunnr.

  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'. "选择屏幕字段名
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_HS00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

endform.                    " PROCESS_LW_VAL_HS00
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_HN00
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KUNNR  text
*----------------------------------------------------------------------*
form process_lw_val_hn00  using    p_kunnr.


  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'. "选择屏幕字段名
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.


  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.





endform.                    " PROCESS_LW_VAL_HN00

*&---------------------------------------------------------------------*
*&      Module  PAI_0500_KUNNR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module pai_0500_kunnr input.

  perform process_check_kunnr_exist using zwf7a-kunnr.

*  perform process_check_kunnr_email

*  clear zwf7a-smtp_addr.

  if zwf7a-smtp_addr is initial.
    clear zwf7a-smtp_addr.
    select single smtp_addr from zwf7a into zwf7a-smtp_addr
      where bukrs = p_bukrs and kunnr = zwf7a-kunnr.

  endif.




endmodule.                 " PAI_0500_KUNNR  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0500  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0500 input.

  case sy-ucomm.
    when 'ZWF7_500S' .
      perform process_ucomm_zwf7_500s.

    when 'ZWF7_500L' .
      perform process_ucomm_zwf7_500l.

  endcase.

endmodule.                 " USER_COMMAND_0500  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_5001
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_500s .
  check not zwf7a-kunnr is initial.

  zwf7a-bukrs = p_bukrs .
*  ZWF7A-SMTP_ADDR

  modify zwf7a from zwf7a .

  clear zwf7a.
  clear adrc-name1.

endform.                    " PROCESS_UCOMM_ZWF7_5001
*&---------------------------------------------------------------------*
*&      Module  PAI_0200_KUNNR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module pai_0200_kunnr input.

  check not zwf7b-kunnr is initial.

  clear izwf7b[] . clear izwf7b.

  clear zeile.

  clear is_checked_200 .

  perform process_check_kunnr_exist using zwf7b-kunnr.

  perform process_check_kunnr_email using zwf7b-kunnr.

endmodule.                 " PAI_0200_KUNNR  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0600  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0600 input.

  case sy-ucomm.
    when 'ZWF7_600E'.
      perform process_ucomm_zwf7_600e.


  endcase.

endmodule.                 " USER_COMMAND_0600  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_600E
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_600e .

  data: rspar_tab  type table of rsparams,
        rspar_line like line of rspar_tab.

  if p_clear_variant = 'X' .

    perform process_get_report_name changing  l_report_name .

    rspar_line-selname = 'P_REPORT'.
    rspar_line-sign    = 'I'.
    rspar_line-option  = 'EQ'.
    rspar_line-low     = l_report_name .
    append rspar_line to rspar_tab.

    rspar_line-selname = 'S_VAR'.
    rspar_line-sign    = 'I'.
    rspar_line-option  = 'CP'.
    rspar_line-low     = 'W7*'.
    append rspar_line to rspar_tab.

    submit zbc00010 with selection-table rspar_tab
                    and return.

  endif.

  if p_clear_pdf = 'X' .

    perform process_clear_unuseful_pdf .

  endif.

endform.                    " PROCESS_UCOMM_ZWF7_600E
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_QL00
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KUNNR  text
*----------------------------------------------------------------------*
form process_lw_val_ql00  using    p_p_kunnr.

  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'. "选择屏幕字段名
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_QL00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


endform.                    " PROCESS_LW_VAL_QL00
*&---------------------------------------------------------------------*
*&      Form  RELOAD_IZWF7B_IN_KUNNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form reload_izwf7b_in_kunnr .

  clear izwf7b[] . clear izwf7b.

  select * from zwf7b into corresponding fields of table izwf7b
    where bukrs = p_bukrs
      and mjahr = zwf7b-mjahr
      and monnm = zwf7b-monnm
      and kunnr in s_kunnr .


endform.                    " RELOAD_IZWF7B_IN_KUNNR
*&---------------------------------------------------------------------*
*&      Form  PROCESS_CHECKING_ZWF7C
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_checking_zwf7c changing p_zwf7_status.

  clear p_zwf7_status .
  clear zwf7c.

  select single * from zwf7c into corresponding fields of zwf7c
    where bukrs = izwf7b-bukrs
      and kunnr = izwf7b-kunnr
      and mjahr = izwf7b-mjahr
      and monnm = izwf7b-monnm .

  if not zwf7c-dmbtri is initial.
    p_zwf7_status = 'Y' .
  else.
    move-corresponding izwf7b to izwf7c .
    append izwf7c . clear izwf7c .
  endif.


endform.                    " PROCESS_CHECKING_ZWF7C
*&---------------------------------------------------------------------*
*&      Form  PROCSSS_DELETE_ZWF7B_BY_IZWF7C
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form procsss_delete_zwf7b_by_izwf7c .


  loop at izwf7c.

    delete from zwf7b where bukrs = izwf7c-bukrs
                        and kunnr = izwf7c-kunnr
                        and mjahr = izwf7c-mjahr
                        and monnm = izwf7c-monnm.

  endloop.

  commit work and wait .


endform.                    " PROCSSS_DELETE_ZWF7B_BY_IZWF7C
*&---------------------------------------------------------------------*
*&      Form  PROCESS_DELETE_SPOOL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SPOOLID  text
*----------------------------------------------------------------------*
form process_delete_spool  using    p_l_spoolid.


  clear ireq[] .

  ireq-rqident   = p_l_spoolid .
  ireq-selected = 'X' .
  ireq-checkbox = 'X' .

  append ireq .



  call function 'RSPO_RLIST_DELETE_SPOOLREQ'
     exporting
       no_dialog          = 'X'
       start_column       = 5
       start_row          = 5
    tables
      requests           = ireq
*     EXCEPTIONS
*       ERROR              = 1
*       OTHERS             = 2
            .



endform.                    " PROCESS_DELETE_SPOOL
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_500L
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_500l .

  type-pools: slis.
  data: gt_fieldcat type  slis_t_fieldcat_alv with header line,
        gs_layout   type  slis_layout_alv,
        gt_events   type  slis_t_event.


  data l_zwf7a like zwf7a occurs 0 with header line.


  select * from zwf7a into corresponding fields of table l_zwf7a
    where bukrs = p_bukrs .

  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZWF7A'
    tables
      fieldcat = gt_fieldcat[].

  gs_layout-zebra          = 'X'.  "设置每行的背景颜色交错显示。
  gs_layout-colwidth_optimize = 'X'.  "ALV输出时候自动优化宽度
  gs_layout-detail_popup   = 'X'.
  gs_layout-no_subtotals   = ''.

  call function 'REUSE_ALV_GRID_DISPLAY'
    exporting
      i_callback_program       = sy-repid
      is_layout                = gs_layout
      i_grid_title             = 'KUNNR Email'
*      i_callback_pf_status_set = 'SET_PF_STATUS'
*      i_callback_user_command  = 'USER_COMMAND'
      it_fieldcat              = gt_fieldcat[]
      i_save                   = 'C'
    tables
      t_outtab                 = l_zwf7a
    exceptions
      program_error            = 1
      others                   = 2.




endform.                    " PROCESS_UCOMM_ZWF7_500L
*&---------------------------------------------------------------------*
*&      Form  PROCESS_APPEND_REGULAR_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_append_regular_list .

  case p_bukrs.
    when 'HS00' or 'QL00' .
      perform appending_izcrs using '{{TO_LIST}}' 'daizhiqing@hydronsh.com' .
*      perform appending_izcrs using '{{TO_LIST}}' 'notice@hydronsh.com' .

    when 'HN00' .
      perform appending_izcrs using '{{TO_LIST}}' 'horien-dzd@hydronsh.com' .
*     perform appending_izcrs using '{{TO_LIST}}' 'notice@hydronsh.com' .

    when 'FS00' .

      perform appending_izcrs using '{{TO_LIST}}' 'fsy-dzd@fushiyuan.com.cn' .

  endcase.

endform.                    " PROCESS_APPEND_REGULAR_LIST
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UCOMM_ZWF7_300E
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_300_TOP_LINE  text
*----------------------------------------------------------------------*
form process_ucomm_zwf7_300e  using    top_line.

  data c_line type i.


  get cursor line c_line.

  c_line = c_line + top_line - 1.

  clear izwf7b .
  read table izwf7b index c_line.

  check not izwf7b-crsnr is initial.

  clear ishow_error[] . clear ishow_error.
  sort ierror .

  loop at ierror where crsnr = izwf7b-crsnr .
    move-corresponding ierror to ishow_error .
    append ishow_error . clear ishow_error.
  endloop.


  perform process_initial_zwf7_300e_alv.

  check not ishow_error[] is initial.

  call function 'REUSE_ALV_GRID_DISPLAY'
  exporting
    i_callback_program       = sy-repid
    is_layout                = gs_layout
    i_grid_title             = 'CRSNR Errors Report'
*      i_callback_pf_status_set = 'SET_PF_STATUS'
*      i_callback_user_command  = 'USER_COMMAND'
    it_fieldcat              = gt_fieldcat[]
    i_save                   = 'C'
  tables
    t_outtab                 = ishow_error
  exceptions
    program_error            = 1
    others                   = 2.



*  message i300(z1) with c_line.


endform.                    " PROCESS_UCOMM_ZWF7_300E
*&---------------------------------------------------------------------*
*&      Form  PROCESS_APPEND_IERRORS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_append_ierrors using p_p_crsnr.

  loop at iexec_protocol .

    move-corresponding iexec_protocol to ierror .
    ierror-crsnr = p_p_crsnr.
    append ierror . clear ierror .

  endloop.




endform.                    " PROCESS_APPEND_IERRORS
*&---------------------------------------------------------------------*
*&      Form  PROCESS_INITIAL_ZWF7_300E_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_initial_zwf7_300e_alv .

  check is_initial_zwf7_300e is initial.

  gs_layout-zebra          = 'X'.  "设置每行的背景颜色交错显示。
  gs_layout-colwidth_optimize = 'X'.  "ALV输出时候自动优化宽度
  gs_layout-detail_popup   = 'X'.
  gs_layout-no_subtotals   = ''.

  clear gt_fieldcat[] . clear gt_fieldcat.

  call function 'ZPRO_GET_ALV_FIELDCAT'
    exporting
      alvnr    = 'ZWF7E'
    tables
      fieldcat = gt_fieldcat[].

  is_initial_zwf7_300e = 'X' .

endform.                    " PROCESS_INITIAL_ZWF7_300E_ALV
*&---------------------------------------------------------------------*
*&      Form  PROCESS_CLEAR_UNUSEFUL_PDF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form process_clear_unuseful_pdf .

  data dir_list like epsfili occurs 0 with header line.
  data dir_zwf7b like zwf7b occurs 0 with header line.

  data dir_name like epsf-epsdirnam .


  dir_name = save_fd .

  call function 'EPS_GET_DIRECTORY_LISTING'
    exporting
      dir_name                     = dir_name
*     FILE_MASK                    = ' '
    tables
      dir_list                     = dir_list
            .

  delete dir_list where rc <> 0 .

  select * from zwf7b into corresponding fields of table dir_zwf7b
    where docsn <> '' .

  sort dir_list.
  sort dir_zwf7b by docsn .

  loop at dir_list .
    read table dir_zwf7b with key docsn = dir_list-name .
    if sy-subrc = 0 .

*      perform process_delete_pdf_file using dir_list-name .

      delete dir_list .
    endif.

  endloop.


  count = lines( dir_list ) .
  tabix = 1 .

  loop at  dir_list .

    call function 'ZPRO_PROGRESS_INDICATOR'
      exporting
        tabix = tabix
        lines = count
        text1 = ' 正在删除PDF:'
        text2 = dir_list-name.

    perform process_delete_pdf_file using dir_list-name .

    tabix = tabix + 1 .

  endloop.

*  perform process_delete_pdf_file using dir_list-name .



endform.                    " PROCESS_CLEAR_UNUSEFUL_PDF
*&---------------------------------------------------------------------*
*&      Form  PROCESS_DELETE_PDF_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_DIR_LIST_NAME  text
*----------------------------------------------------------------------*
form process_delete_pdf_file  using    p_dir_list_name.


  data filename type string .
  data rc type i.

  concatenate save_fd p_dir_list_name into filename .

  delete dataset filename .

*  call method cl_gui_frontend_services=>file_delete
*    exporting
*      filename = lc_filename
*    changing
*      rc       = rc.


endform.                    " PROCESS_DELETE_PDF_FILE
*&---------------------------------------------------------------------*
*&      Module  SHOW_RCOMP  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module show_rcomp output.

  clear it880 .

  read table it880 with key rcomp = p_bukrs .

  t880-name1 = it880-name1.


endmodule.                 " SHOW_RCOMP  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0999  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0999 input.

endmodule.                 " USER_COMMAND_0999  INPUT
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_FS00
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KUNNR  text
*----------------------------------------------------------------------*
form process_lw_val_fs00  using    p_kunnr.

  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'. "选择屏幕字段名
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_FS00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


endform.                    " PROCESS_LW_VAL_FS00
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_HS00_X1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KUNNR  text
*----------------------------------------------------------------------*
form process_lw_val_hs00_x1  using    p_kunnr.

  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'.
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_HS00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_CV00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_SF00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_QL00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


  lw_val-selname = 'P_ONLY'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.


  select single vkbur into knvv-vkbur from knvv
    where kunnr = ikna1-kunnr
      and vkorg = p_bukrs
      and vkbur = '0007' .

  if sy-subrc = 0 .
    lw_val-selname = 'P_A2'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = 'X' .
    append lw_val. clear lw_val.

    lw_val-selname = 'P_A1'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = '' .
    append lw_val. clear lw_val.
  else.
    lw_val-selname = 'P_A2'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = '' .
    append lw_val. clear lw_val.

    lw_val-selname = 'P_A1'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = 'X' .
    append lw_val. clear lw_val.
  endif .


  lw_val-selname = 'P_ZTERM'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_KNVV'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


  lw_val-selname = 'P_T2'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


endform.                    " PROCESS_LW_VAL_HS00_X1
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_HN00_X1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KUNNR  text
*----------------------------------------------------------------------*
form process_lw_val_hn00_x1  using    p_kunnr.

  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'.
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_HN00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


  lw_val-selname = 'P_ONLY'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.


  select single vkbur into knvv-vkbur from knvv
    where kunnr = ikna1-kunnr
      and vkorg = p_bukrs
      and vkbur = '0007' .

  if sy-subrc = 0 .
    lw_val-selname = 'P_A2'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = 'X' .
    append lw_val. clear lw_val.

    lw_val-selname = 'P_A1'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = '' .
    append lw_val. clear lw_val.
  else.
    lw_val-selname = 'P_A2'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = '' .
    append lw_val. clear lw_val.

    lw_val-selname = 'P_A1'.
    lw_val-kind = 'P'.
    lw_val-sign = 'I'.
    lw_val-option = 'EQ'.
    lw_val-low = 'X' .
    append lw_val. clear lw_val.
  endif .

  lw_val-selname = 'P_ZTERM'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_KNVV'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_T2'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

endform.                    " PROCESS_LW_VAL_HN00_X1
*&---------------------------------------------------------------------*
*&      Form  PROCESS_LW_VAL_FS00_X1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KUNNR  text
*----------------------------------------------------------------------*
form process_lw_val_fs00_x1  using    p_kunnr.

  clear lw_val[]. clear lw_val.

  lw_val-selname = 'P_GJAHR'.
  lw_val-kind = 'P'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-mjahr . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_MONAT'. "选择屏幕字段名
  lw_val-kind = 'S'. "选择屏幕字段类型(P->PARAMETERS;S->SELECT-OPTIONS)
  lw_val-sign = 'I'. "标识（I->包含；E->排除)
  lw_val-option = 'EQ'. "选项
  lw_val-low = zwf7b-monnm . "从(下限）
  append lw_val. clear lw_val.

  lw_val-selname = 'S_KUNNR'.
  lw_val-kind = 'S'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = p_kunnr .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_HN00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_FS00'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'NOT_ZERO'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_ONLY'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = '' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_A1'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_ZTERM'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_KNVV'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.

  lw_val-selname = 'P_T2'.
  lw_val-kind = 'P'.
  lw_val-sign = 'I'.
  lw_val-option = 'EQ'.
  lw_val-low = 'X' .
  append lw_val. clear lw_val.


endform.                    " PROCESS_LW_VAL_FS00_X1

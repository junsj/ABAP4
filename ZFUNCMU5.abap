*&---------------------------------------------------------------------*
*&  Include           ZBC00008
*&---------------------------------------------------------------------*

tables zcrs  .
tables zcrse .

data:   izcrs like zcrs occurs 0 with header line.

data:   p_crsnr like zcrs-crsnr.
data:   p_crsnp like zcrs-crsnp value 1.


data:   p_cmd like sxpgcolist-parameters.
data:   iexec_protocol like btcxpm occurs 0 with header line.

constants p_host(6) value 'DEV300' .

data: l_date(10) type c,
      l_time(10) type c,
      sdate(20) type c..

*&---------------------------------------------------------------------*
*&      Form  APPENDING_IZCRS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0165   text
*      -->P_ISERVERDATA_HOSTNAME  text
*----------------------------------------------------------------------*
form appending_izcrs  using    p_sgtyp
                               p_sgtxt.

  izcrs-crsnr = p_crsnr .
  izcrs-crsnp = p_crsnp .
  izcrs-sgtyp = p_sgtyp .
  izcrs-sgtxt = p_sgtxt .

  condense izcrs-sgtxt.
  append izcrs . clear izcrs .

  p_crsnp = p_crsnp + 1 .

endform.                    " APPENDING_IZCRS

*&---------------------------------------------------------------------*
*&      Form  SYNC_TABLES_TO_CLIENT_300
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form sync_tables_to_client_300 .

  call function 'ZFUN_SYNC_TABLES'
    destination p_host
    exporting
      p_zcrs = 'X'
    tables
      t_zcrs = izcrs.

endform.                    " SYNC_TABLES_TO_CLIENT_300

*&---------------------------------------------------------------------*
*&      Form  EXCUTE_PY_COMMAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_CRSNR  text
*----------------------------------------------------------------------*
form excute_python_command  using  p_py  p_p_crsnr p_message.

  concatenate p_py p_p_crsnr into p_cmd separated by space .

  clear iexec_protocol[].

  call function 'SXPG_CALL_SYSTEM'
    destination p_host
    exporting
      commandname           = 'Z_PYTHON'
      additional_parameters = p_cmd
    tables
      exec_protocol         = iexec_protocol.


  if p_message = 'X' .
    loop at iexec_protocol.
      write:/ iexec_protocol-message.
    endloop.
    skip.

  endif.

endform.                    " EXCUTE_PY_COMMAND
*&---------------------------------------------------------------------*
*&      Form  FORMAT_DATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_DATUM  text
*      -->P_CHANGE  text
*      -->P_SDATE  text
*----------------------------------------------------------------------*
form format_date  using    p_sy_datum
                  changing  p_sdate.

  data l_date(10) type c.
  data y(4) type c.
  data m(2) type c.
  data d(2) type c.

  check not p_sy_datum is initial.

  l_date = p_sy_datum .

  y =  p_sy_datum(4) .
  m = p_sy_datum+4(2) .
  d = p_sy_datum+6(2) .

  concatenate y '/' m '/' d into p_sdate .

endform.                    " FORMAT_DATE
*&---------------------------------------------------------------------*
*&      Form  FORMAT_TIME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_STRTTIME  text
*      <--P_STRTTIME  text
*----------------------------------------------------------------------*
form format_time  using    i_strttime
                  changing o_strttime.

  data h(2) type c.
  data m(2) type c.
  data s(2) type c.

  check not i_strttime is initial.

  h = i_strttime(2) .
  m = i_strttime+2(2) .
  s = i_strttime+4(2) .

  concatenate h ':' m ':' s into o_strttime.

endform.                    " FORMAT_TIME
*&---------------------------------------------------------------------*
*&      Form  PROCESS_APPEND_ZCRSE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_CRSNR  text
*----------------------------------------------------------------------*
form process_append_zcrse  using    p_p_crsnr.

  data l_zcrse like zcrse occurs 0 with header line.

*  write:/ p_p_crsnr color 4.
*  write:/ sy-uline .

  loop at iexec_protocol .
    l_zcrse-crsnr =  p_p_crsnr.
    l_zcrse-crsnp = sy-tabix .
    move-corresponding iexec_protocol to l_zcrse .
    append l_zcrse . clear l_zcrse.
  endloop.

  modify zcrse from table l_zcrse .
  commit work and wait.

endform.                    " PROCESS_APPEND_ZCRSE
*&---------------------------------------------------------------------*
*&      Form  APPENDING_IZCRS_MAIL_TO_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_SMTP_ADDR  text
*----------------------------------------------------------------------*
form appending_izcrs_mail_to_list  using    p_p_smtp_addr.

  data l_add1 like zwf7a-smtp_addr .
  data l_add2 like zwf7a-smtp_addr .
  data l_add  like zwf7a-smtp_addr .

  l_add = p_p_smtp_addr.

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



endform.                    " APPENDING_IZCRS_MAIL_TO_LIST

<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr="http://transpect.io"  
  version="1.0"
  name="hub2bits"
  >
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" />
  
  <p:input port="source" primary="true" sequence="false"/>
  <p:input port="models" sequence="true"/>
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:input port="stylesheet"/>
  <p:output port="result" primary="true"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <tr:xslt-mode prefix="hub2bits/05" mode="default">
    <p:input port="source">
      <p:pipe step="hub2bits" port="source"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe step="hub2bits" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </tr:xslt-mode>
  
  <tr:xslt-mode prefix="hub2bits/20" mode="clean-up">
    <p:input port="models">
      <p:pipe step="hub2bits" port="models"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe step="hub2bits" port="stylesheet"/></p:input>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </tr:xslt-mode>

</p:declare-step>

<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:bc="http://transpect.le-tex.de/book-conversion"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"  
  xmlns:din="http://din.de/namespace"
  xmlns:letex="http://www.le-tex.de/namespace"
  version="1.0"
  name="hub2hobots"
  >
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" />
  
  <p:input port="source" primary="true" sequence="false"/>
  <p:input port="models" sequence="true"/>
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:input port="stylesheet"/>
  <p:output port="result" primary="true"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/xproc-util/xslt-mode/xslt-mode.xpl"/>
  
  <letex:xslt-mode prefix="hub2hobots/05" mode="default">
    <p:input port="source">
      <p:pipe step="hub2hobots" port="source"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe step="hub2hobots" port="stylesheet"/></p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </letex:xslt-mode>
  
  <letex:xslt-mode prefix="hub2hobots/20" mode="clean-up">
    <p:input port="models">
      <p:pipe step="hub2hobots" port="models"/>
    </p:input>
    <p:input port="stylesheet"><p:pipe step="hub2hobots" port="stylesheet"/></p:input>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </letex:xslt-mode>

</p:declare-step>

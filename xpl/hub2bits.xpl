<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tr="http://transpect.io"  
  xmlns:jats="http://jats.nlm.nih.gov"
  version="1.0"
  name="hub2bits"
  type="jats:hub2bits"
  >
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" required="false" select="resolve-uri('status')"/>
  <p:option name="fallback-xsl" select="'http://transpect.io/hub2bits/xsl/hub2bits.xsl'"/>
  <p:option name="fallback-xpl" select="'http://transpect.io/hub2bits/xpl/fallback.xpl'"/>
  <p:option name="load" required="false" select="'hub2bits/hub2bits'"/>

  <p:input port="source" primary="true" />
  <p:input port="paths" kind="parameter" primary="true"/>

  <p:input port="models">
    <p:inline>
      <c:models>
        <c:model href="https://hobots.hogrefe.com/schema/hobots.rng" type="application/xml"
          schematypens="http://relaxng.org/ns/structure/1.0"/>
      </c:models>
    </p:inline>
  </p:input>

  <p:output port="result" primary="true" />
  
  <p:import href="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xml-model/xpl/prepend-xml-model.xpl" />
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>

  <tr:simple-progress-msg name="start-msg" file="hub2jats-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting Hub to JATS/BITS/HoBoTS XML conversion</c:message>
          <c:message xml:lang="de">Beginne Konvertierung von Hub nach JATS/BITS/HoBoTS XML</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <p:sink/>
  
  <p:wrap wrapper="cx:document" match="/*">
    <p:input port="source">
      <p:pipe port="models" step="hub2bits"/>
    </p:input>
  </p:wrap>
  <p:add-attribute name="models" attribute-name="port" attribute-value="models" match="/*"/>
  
  <p:sink/>
  
  <tr:dynamic-transformation-pipeline>
    <p:with-option name="load" select="$load"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fallback-xpl" select="$fallback-xpl"/>
    <p:with-option name="fallback-xsl" select="$fallback-xsl"/>
    <p:input port="source">
      <p:pipe port="source" step="hub2bits"/>
    </p:input>
    <p:input port="additional-inputs">
      <p:pipe port="result" step="models"/>
    </p:input>
    <p:input port="options"><p:empty/></p:input>
    <p:pipeinfo>
      <examples xmlns="http://transpect.io" 
        eval-pipeline-input-uri="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl#eval-pipeline"
        option-uri="http://transpect.io/cascade/xpl/dynamic-transformation-pipeline.xpl#load"
        option-value="hub2bits/hub2bits.xpl">
<!--        <file href="http://this.transpect.io/a9s/common/hub2bits/hub2bits.xpl"/>-->
        <collection dir-uri="http://this.transpect.io/a9s/" file="hub2bits/hub2bits.xpl"/>
        <generator-collection dir-uri="http://this.transpect.io/a9s/" file="hub2bits/hub2bits.xpl.xsl"/>
      </examples>
    </p:pipeinfo>  
  </tr:dynamic-transformation-pipeline>

  <tr:prepend-xml-model name="prepend-xml-model">
    <p:input port="models">
      <p:pipe step="hub2bits" port="models"/>
    </p:input>
  </tr:prepend-xml-model>

  <tr:simple-progress-msg name="success-msg" file="hub2jats-success.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Successfully finished Hub to JATS/BITS/HoBoTS XML conversion</c:message>
          <c:message xml:lang="de">Konvertierung von Hub nach JATS/BITS/HoBoTS XML erfolgreich abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
</p:declare-step>

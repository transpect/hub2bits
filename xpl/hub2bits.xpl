<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:bc="http://transpect.le-tex.de/book-conversion"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"  
  xmlns:jats="http://jats.nlm.nih.gov"
  xmlns:letex="http://www.le-tex.de/namespace"
  version="1.0"
  name="hub2hobots"
  type="jats:hub2hobots"
  >
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" required="false" select="resolve-uri('status')"/>
  
  <p:input port="source" primary="true" />
  <p:input port="paths" kind="parameter" primary="true"/>
  <p:output port="result" primary="true" />
  
  <p:import href="http://transpect.le-tex.de/book-conversion/converter/xpl/dynamic-transformation-pipeline.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/xml-model/prepend-xml-model.xpl" />
  <p:import href="http://transpect.le-tex.de/book-conversion/converter/xpl/simple-progress-msg.xpl"/>
  
  <letex:simple-progress-msg name="start-msg" file="hub2jats-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting Hub to JATS/BITS/HoBoTS XML conversion</c:message>
          <c:message xml:lang="de">Beginne Konvertierung von Hub nach JATS/BITS/HoBoTS XML</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </letex:simple-progress-msg>
  
  <p:sink/>
  
  <p:identity name="schema">
    <p:input port="source">
      <p:inline>
        <c:models>
          <c:model href="https://hobots.hogrefe.com/schema/hobots.rng" type="application/xml"
            schematypens="http://relaxng.org/ns/structure/1.0" />
        </c:models>
      </p:inline>
    </p:input>
  </p:identity>
  
  <p:wrap wrapper="cx:document" match="/*"/>
  <p:add-attribute name="models" attribute-name="port" attribute-value="models" match="/*"/>
  
  <p:sink/>
  
  <transpect:dynamic-transformation-pipeline load="hub2hobots/hub2hobots">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="source">
      <p:pipe port="source" step="hub2hobots"/>
    </p:input>
    <p:input port="additional-inputs">
      <p:pipe port="result" step="models"/>
    </p:input>
    <p:input port="options"><p:empty/></p:input>
    <p:pipeinfo>
      <examples xmlns="http://www.le-tex.de/namespace/transpect" 
        eval-pipeline-input-uri="http://transpect.le-tex.de/book-conversion/converter/xpl/dynamic-transformation-pipeline.xpl#eval-pipeline"
        option-uri="http://transpect.le-tex.de/book-conversion/converter/xpl/dynamic-transformation-pipeline.xpl#load"
        option-value="hub2hobots/hub2hobots.xpl">
        <file href="http://customers.le-tex.de/generic/book-conversion/adaptions/common/hub2hobots/hub2hobots.xpl"/>
        <collection dir-uri="http://customers.le-tex.de/generic/book-conversion/adaptions/" file="hub2hobots/hub2hobots.xpl"/>
        <generator-collection dir-uri="http://customers.le-tex.de/generic/book-conversion/adaptions/" file="hub2hobots/hub2hobots.xpl.xsl"/>
      </examples>
    </p:pipeinfo>  
  </transpect:dynamic-transformation-pipeline>

  <letex:prepend-xml-model name="prepend-xml-model">
    <p:input port="models">
      <p:pipe step="schema" port="result"/>
    </p:input>
  </letex:prepend-xml-model>

  <letex:simple-progress-msg name="success-msg" file="hub2jats-success.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Successfully finished Hub to JATS/BITS/HoBoTS XML conversion</c:message>
          <c:message xml:lang="de">Konvertierung von Hub nach JATS/BITS/HoBoTS XML erfolgreich abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </letex:simple-progress-msg>
</p:declare-step>

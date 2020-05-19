<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:tr="http://transpect.io"  
  xmlns:jats="http://jats.nlm.nih.gov"
  version="1.0"
  name="hub2bits-store-chunks"
  type="jats:store-chunks"
  >
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" required="false" select="resolve-uri('status')"/>
  <p:option name="include-method" select="'xinclude'">
    <p:documentation>Currently, if the value is not 'xinclude', related-object elements will 
    be created for linking to the chunks.</p:documentation>
  </p:option>
  <p:option name="dtd-version" select="''">
    <p:documentation>If non-empty, will be added as @dtd-version to every split chunk.</p:documentation>
  </p:option>

  <p:input port="source" primary="true" >
    <p:documentation>A BITS document with xml:base attributes at the designated chunk roots.</p:documentation>
  </p:input>
  <p:input port="xsl">
    <p:document href="../xsl/store-chunks.xsl"/>
  </p:input>
  
  <p:input port="models">
    <p:inline>
      <c:models>
        <c:model href="http://jats.nlm.nih.gov/extensions/bits/2.0/rng/BITS-book2.rng" type="application/xml" 
          schematypens="http://relaxng.org/ns/structure/1.0"/>
      </c:models>
    </p:inline>
  </p:input>

  <p:output port="result" primary="true">
    <p:documentation>A ToC based on the @xml:base attributes that mark the split destinations.</p:documentation>
    <p:pipe port="result" step="prepend-xml-model-to-toc"/>
  </p:output>
  <p:serialization port="result" indent="true" omit-xml-declaration="false"/>
  
  <p:import href="http://transpect.io/xproc-util/xml-model/xpl/prepend-xml-model.xpl" />
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  
  <p:xslt name="export-chunks" initial-mode="split">
    <p:input port="stylesheet">
      <p:pipe port="xsl" step="hub2bits-store-chunks"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:with-param name="include-method" select="$include-method"/>
    <p:with-param name="dtd-version" select="$dtd-version"/>
  </p:xslt>
  
  <tr:prepend-xml-model name="prepend-xml-model-to-toc">
    <p:input port="models">
      <p:pipe step="hub2bits-store-chunks" port="models"/>
    </p:input>
  </tr:prepend-xml-model>

  <p:sink name="sink1"/>

  <p:for-each>
    <p:iteration-source>
      <p:pipe port="secondary" step="export-chunks"/>
    </p:iteration-source>
    <tr:prepend-xml-model name="prepend-xml-model">
      <p:input port="models">
        <p:pipe step="hub2bits-store-chunks" port="models"/>
      </p:input>
    </tr:prepend-xml-model>
    <p:store omit-xml-declaration="false">
      <p:with-option name="href" select="base-uri()"/>
    </p:store>
  </p:for-each>
  
</p:declare-step>

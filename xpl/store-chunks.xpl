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
    be created for linking to contained chunks.</p:documentation>
  </p:option>
  <p:option name="dtd-version" select="''">
    <p:documentation>If non-empty, will be added as @dtd-version to every split chunk.</p:documentation>
  </p:option>

  <p:input port="source" primary="true" >
    <p:documentation>A BITS document with xml:base attributes at the designated chunk roots.
    These chunk roots can be book-part, front-matter-part, sec, app, etc.
    The chunk roots are typically calculated in 'split-uri' mode which in turn is applied
    to each element in 'default' mode. See the comments about split-uri mode in hub2bits.xsl.
    It is important to know that the xml:base attributes won’t be created by default. 
    It is necessary to import hub2bits.xsl and to implement 'split-uri' in such a way that
    the xml:base attributes will be attached to the future splitting roots.
    It is not essential to go from Hub XML to BITS first. This splitting step and the preceding
    xml:base generation step may be applied to a BITS source document, too.
    </p:documentation>
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
  <p:output port="chunks" sequence="true">
    <p:pipe port="chunks" step="store-chunks"/>
  </p:output>
  <p:output port="adjusted-links">
    <p:pipe port="not-matched" step="adjusted-links-and-chunks"/>
  </p:output>
  <p:serialization port="adjusted-links" indent="true" omit-xml-declaration="false"/>
  
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

  <p:split-sequence name="adjusted-links-and-chunks" test="not(ends-with(base-uri(), 'links-adjusted.xml'))">
    <p:input port="source">
      <p:pipe port="secondary" step="export-chunks"/>
    </p:input>
  </p:split-sequence>

  <p:for-each name="store-chunks">
    <p:output port="chunks">
      <p:pipe port="result" step="prepend-xml-model"/>
    </p:output>
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

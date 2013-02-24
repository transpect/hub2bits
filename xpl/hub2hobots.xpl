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
  
  <p:option name="srcpaths" required="false" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:input port="source" primary="true" />
  <p:input port="paths" kind="parameter" primary="true"/>
  <p:output port="result" primary="true" />
  
  <p:import href="http://transpect.le-tex.de/book-conversion/converter/xpl/dynamic-transformation-pipeline.xpl"/>
  
  <bc:dynamic-transformation-pipeline load="hub2hobots/hub2hobots">
    <p:with-option name="srcpaths" select="$srcpaths"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </bc:dynamic-transformation-pipeline>

  <p:xslt>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:template match="/">
            <xsl:text>&#xa;</xsl:text>
            <xsl:processing-instruction name="xml-model" 
                select="'href=&#x22;http://hobots.hogrefe.com/schema/hobots.rng&#x22; type=&#x22;application/xml&#x22; schematypens=&#x22;http://relaxng.org/ns/structure/1.0&#x22;'"/>
            <xsl:text>&#xa;</xsl:text>
            <!--<xsl:processing-instruction name="xml-model" 
                select="concat('href=&#x22;http://www.le-tex.de/resource/schema/hub/', $hub-version, 
                '/hub.rng&#x22; type=&#x22;application/xml&#x22; schematypens=&#x22;http://purl.oclc.org/dsdl/schematron&#x22;')"/>
            <xsl:text>&#xa;</xsl:text>-->
            <xsl:copy-of select="*"/>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
</p:declare-step>

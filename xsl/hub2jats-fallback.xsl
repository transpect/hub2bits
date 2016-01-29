<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:jats="http://jats.nlm.nih.gov" 
  xmlns:dbk="http://docbook.org/ns/docbook" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  exclude-result-prefixes="css jats dbk xs" version="2.0">

  <xsl:import href="hub2bits.xsl"/>

  <!-- General structure. Overridden because of metadata concerns-->
  <xsl:template match="dbk:book | dbk:hub" mode="default" priority="2">
    <article>
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:copy-of select="@css:version"/>
      <xsl:attribute name="article-type" select="'research-article'"/>
      <xsl:attribute name="css:rule-selection-attribute" select="'content-type style-type'"/>
      <xsl:attribute name="source-dir-uri" select="dbk:info/dbk:keywordset[@role eq 'hub']/dbk:keyword[@role eq 'source-dir-uri']"/>
      <xsl:sequence select="$dtd-version-att"/>
      <xsl:choose>
        <xsl:when test="@xml:lang">
          <xsl:copy-of select="@xml:lang"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="key('jats:style-by-type', 'NormalParagraphStyle')[@xml:lang ne '']">
            <xsl:copy-of select="key('jats:style-by-type', 'NormalParagraphStyle')/@xml:lang, @xml:lang"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="matter"/>
    </article>
  </xsl:template>
  
  <xsl:template match="dbk:info" mode="default">
    <xsl:variable name="source-basename" select="dbk:keywordset[@role eq 'hub']/dbk:keyword[matches(@role, 'source-basename')]"/>
    <journal-meta>
      <journal-id journal-id-type="nlm-ta">
        <xsl:value-of select="replace($source-basename, '(^\w+)(_\d+_\d+)' , '$1')"/>
      </journal-id>
      <journal-title-group>
      <xsl:if test="matches(replace($source-basename, '(^\w+)(_\d+_\d+)' , '$1'), 'CSMI')">
        <journal-title>Clinical Sports Medicine International</journal-title>
      </xsl:if>
      </journal-title-group>
      <xsl:if test="matches(replace($source-basename, '(^\w+)(_\d+_\d+)' , '$1'), 'CSMI')">
        <issn pub-type="ppub">1617-9870</issn>
      </xsl:if>
    </journal-meta>
    <article-meta>
      <xsl:apply-templates select="dbk:abstract/dbk:section[dbk:title[matches(text(),'[kK]ey\s?[wW]ords')]]" mode="#current">
        <xsl:with-param name="process" select="true()" as="xs:boolean?"/>
      </xsl:apply-templates>
      <xsl:if test="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')]">
        <article-id book-id-type="doi">
          <xsl:value-of select="replace(string-join(dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')], ''), '^.+doi\.org/', '')"/>
        </article-id>
        <article-id book-id-type="publisher">
          <xsl:value-of select="replace(string-join(dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')], ''), '^(.+doi\.org/.+/)?(\d{5})-.+$', '$2')"/>
        </article-id>
      </xsl:if>
      <title-group>
        <xsl:apply-templates select="dbk:title" mode="#current">
          <xsl:with-param name="process" select="true()" as="xs:boolean?"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="dbk:subtitle" mode="#current">
          <xsl:with-param name="process" select="true()" as="xs:boolean?"/>
        </xsl:apply-templates>
      </title-group>
      <xsl:if test="dbk:authorgroup">
        <contrib-group>
          <xsl:apply-templates select="dbk:authorgroup" mode="#current">
            <xsl:with-param name="process" select="true()" as="xs:boolean"></xsl:with-param>
          </xsl:apply-templates>
        </contrib-group>
      </xsl:if>
      <xsl:apply-templates select="dbk:authorgroup/dbk:author/dbk:address" mode="default"/>
      <xsl:apply-templates select="dbk:para[matches(@role, 'quotation')]"/>
      <xsl:if test="dbk:seriesvolnums">
        <article-volume-number>
          <xsl:value-of select="dbk:seriesvolnums"/>
        </article-volume-number>
      </xsl:if>
      <pub-date pub-type="ppub">
        <year>
          <xsl:value-of select="replace($source-basename, '(^\w+)_(\d+)_(\d+)' , '$2')"/>
        </year>
      </pub-date>
      <volume>
        <xsl:value-of select="replace($source-basename, '(^\w+)_(\d+)_(\d)0(\d)' , '$3')"/>
      </volume>
      <issue>
        <xsl:value-of select="replace($source-basename, '(^\w+)_(\d+)_(\d)0(\d)' , '$4')"/>
      </issue>
      <fpage>
        <xsl:value-of select="replace(dbk:abstract/dbk:para[matches(@role, 'quotation')], '(^.*):\s*(\d+)-(\d+)[\s\S]?', '$2')"/></fpage>
      <lpage><xsl:value-of select="replace(dbk:abstract/dbk:para[matches(@role, 'quotation')], '(^.*):\s*(\d+)-(\d+)[\s\S]?', '$3')"/></lpage>
      <xsl:if test="dbk:edition">
        <edition>
          <xsl:value-of select="dbk:edition"/>
        </edition>
      </xsl:if>
      <xsl:call-template name="custom-meta-group"/>
      <xsl:apply-templates select="dbk:info[dbk:keywordset[@role eq 'hub']]/dbk:keywordset[@role eq 'hub']" mode="#current"/>
      <xsl:apply-templates select="dbk:abstract" mode="#current">
        <xsl:with-param name="process" select="true()" as="xs:boolean"/>
      </xsl:apply-templates>
    </article-meta>
  </xsl:template>
  
  <xsl:function name="jats:matter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="name" select="$elt/local-name()" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$name = ('info', 'title', 'subtitle')"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface', 'partintro', 'acknowledgements', 'dedication', 'abstract')"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:colophon[@role = ('front-matter-blurb', 'frontispiz', 'copyright-page', 'title-page', 'about-contrib')]"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$name = ('section')"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="$name = ('appendix', 'index', 'glossary', 'bibliography')"><xsl:sequence select="'back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
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
      <article-meta>
        <xsl:if test="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')]">
          <article-id book-id-type="doi">
            <xsl:value-of select="replace(string-join(dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')], ''), '^.+doi\.org/', '')"/>
          </article-id>
          <article-id book-id-type="publisher">
            <xsl:value-of select="replace(string-join(dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')], ''), '^(.+doi\.org/.+/)?(\d{5})-.+$', '$2')"/>
          </article-id>
        </xsl:if>
        <article-title-group>
          <xsl:apply-templates select="dbk:title" mode="#current"/>
          <xsl:apply-templates select="dbk:subtitle" mode="#current"/>
        </article-title-group>
        <xsl:if test="dbk:info/dbk:authorgroup">
          <contrib-group>
            <xsl:apply-templates select="dbk:info/dbk:authorgroup" mode="#current"/>
          </contrib-group>
        </xsl:if>
        <xsl:if test="dbk:info/dbk:seriesvolnums">
          <article-volume-number>
            <xsl:value-of select="dbk:info/dbk:seriesvolnums"/>
          </article-volume-number>
        </xsl:if>
        <xsl:if test="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_isbn')]">
          <xsl:for-each select="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_isbn')]">
            <xsl:variable name="type" select="replace(@role, '^.+_ch_isbn_', '')" as="xs:string+"/>
            <isbn publication-format="{$type}">
              <xsl:value-of select="replace(., '\s+\(.+\)$', '')"/>
            </isbn>
          </xsl:for-each>
        </xsl:if>
        <xsl:if test="dbk:info/dbk:publisher/dbk:publishername">
          <publisher>
              <publisher-name>
                <xsl:value-of select="dbk:info/dbk:publisher/dbk:publishername"/>
              </publisher-name>
              <xsl:if test="dbk:info/dbk:publisher/dbk:address">
                <publisher-loc>
                  <xsl:value-of select="dbk:info/dbk:publisher/dbk:address"/>
                </publisher-loc>
              </xsl:if>
          </publisher>
        </xsl:if>
        <xsl:if test="dbk:info/dbk:edition">
          <edition>
            <xsl:value-of select="dbk:info/dbk:edition"/>
          </edition>
        </xsl:if>
        <xsl:if test="dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publishing_year')] and
                      dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publisher')]">
          <permissions>
            <copyright-statement>
              <xsl:value-of select="concat('© ', 
                                           string-join(dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publishing_year')], ''),
                                           '&#160;', 
                                           string-join(dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publisher(_-_.+)?$')], ''))"/>
            </copyright-statement>
          </permissions>
        </xsl:if>
        <xsl:call-template name="custom-meta-group"/>
        <xsl:apply-templates select="dbk:info[dbk:keywordset[@role eq 'hub']]/dbk:keywordset[@role eq 'hub']" mode="#current"/>
      </article-meta>
      <xsl:call-template name="matter"/>
    </article>
  </xsl:template>

  <xsl:function name="jats:matter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="name" select="$elt/local-name()" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$name = ('info', 'title', 'subtitle')"><xsl:sequence select="''"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface', 'partintro', 'acknowledgements', 'dedication', 'abstract')"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:colophon[@role = ('front-matter-blurb', 'frontispiz', 'copyright-page', 'title-page', 'about-contrib')]"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$name = ('section')"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="$name = ('appendix', 'index', 'glossary', 'bibliography')"><xsl:sequence select="'back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
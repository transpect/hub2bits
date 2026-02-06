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

  <xsl:param name="vocab" as="xs:string" select="'jats'"/>
  <xsl:param name="dtd-version" as="xs:string" select="'1.1'" />

  <!-- General structure. Overridden because of metadata concerns-->
  <xsl:template match="dbk:book | dbk:hub" mode="default" priority="2">
    <article>
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:copy-of select="@css:version"/>
      <xsl:attribute name="article-type" select="jats:article-type(.)"/>
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

  <xsl:function name="jats:article-type" as="xs:string">
    <xsl:param name="root" as="element(*)"/>
    <xsl:value-of select="'research-article'"/>
  </xsl:function>
  
  <xsl:template match="/*/dbk:info" mode="default">
    <xsl:variable name="context" select="parent::*/local-name()" as="xs:string"/>
    <xsl:variable name="elts-for-grouping" as="element()*"
                  select="dbk:title, parent::*/dbk:title, 
                          dbk:subtitle, parent::*/dbk:subtitle,
                          dbk:titleabbrev, parent::*/dbk:titleabbrev,
                          dbk:authorgroup, dbk:author, dbk:editor, dbk:othercredit,
                          (dbk:copyright|dbk:legalnotice), dbk:bibliomisc, dbk:cover"/>
    <xsl:call-template name="meta"/>
    <article-meta>
      <xsl:apply-templates select="@srcpath" mode="#current"/>
      <xsl:call-template name="title-info">
        <xsl:with-param name="elts" select="$elts-for-grouping"/>
        <xsl:with-param name="context" select="parent::*"/>
      </xsl:call-template>
      <xsl:apply-templates select="* except ($elts-for-grouping, css:rules, dbk:keywordset[@role = $kwd-group-keywordset-roles])" mode="#current"/>
      <xsl:call-template name="kwd-group"/>
      <xsl:call-template name="custom-meta-group"/>
    </article-meta>
  </xsl:template>
  
  <xsl:template match="dbk:hub/dbk:title | dbk:hub/dbk:info/dbk:title" mode="default" priority="5">
    <article-title>
      <xsl:apply-templates  select="@xml:id, @xml:base, node(), ../dbk:itermset/*, ../dbk:info/dbk:itermset/*" mode="#current"/>
    </article-title>
  </xsl:template>

  <xsl:template name="meta">
    <journal-meta/>
  </xsl:template>
  
  <xsl:function name="jats:matter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="name" select="$elt/local-name()" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$name = ('info', 'title', 'subtitle')"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface', 'partintro', 'dedication', 'abstract')"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$name = ('acknowledgements', 'note')">
        <xsl:sequence select="if ($elt[following-sibling::*[1][self::dbk:appendix 
                                                               or 
                                                               not(following-sibling::*[self::dbk:section])]])
                              then 'back' 
                              else 'front'"/>
      </xsl:when>
      <xsl:when test="$elt/self::dbk:colophon[@role = ('front-matter-blurb', 'frontispiz', 'copyright-page', 'title-page', 'about-contrib')]"><xsl:sequence select="'front'"/></xsl:when>
      <xsl:when test="$name = ('section')"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="$name = ('appendix', 'index', 'glossary', 'bibliography')"><xsl:sequence select="'back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="dbk:revhistory" mode="default">
    <history>
      <xsl:apply-templates select="node() except (dbk:info | dbk:title | dbk:titleabbrev)" mode="#current"/>
    </history>
  </xsl:template>

</xsl:stylesheet>
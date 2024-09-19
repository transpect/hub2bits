<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:jats="http://jats.nlm.nih.gov"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:functx="http://www.functx.com"
  xmlns:hub2htm="http://transpect.io/hub2htm"
  xmlns:hub="http://transpect.io/hub"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="css dbk functx jats xs xlink hub hub2htm mml tr"
  version="2.0">

  <xsl:import href="http://transpect.io/hub2html/xsl/css-atts2wrap.xsl"/>

  <xsl:output method="xml" cdata-section-elements="tex-math" omit-xml-declaration="no">
    <!-- cdata-section-elements not supported by XML Calabash 1, can’t use it in p:serialization.
    You need to have a separate postprocessing Saxon run if this is important -->
  </xsl:output>

  <xsl:param name="srcpaths" select="'no'"/>

  <xsl:param name="css:wrap-namespace" as="xs:string" select="''"/>
  
  <xsl:param name="vocab" as="xs:string" select="'bits'">
    <!-- i.e. "jats", "jats publishing", "jats archiving", "jats articleauthoring" | "bits"-->
  </xsl:param>
  <xsl:param name="dtd-version" as="xs:string" select="'2.0'" />
  
  <xsl:variable name="jats:vocabulary" as="xs:string+" select="tokenize($vocab, '\s+')"/>

  <xsl:variable name="jats:appendix-to-bookpart" as="xs:boolean" select="false()"/>
  <!-- "footnotes|endnotes" include footnotes in <fn-group> -->
  <xsl:variable name="jats:notes-type" select="'footnotes'" as="xs:string"/>
  <!-- "yes|no" render <fn-group> for each chapter if $jats:notes-type = 'yes' -->
  <xsl:variable name="jats:notes-per-chapter" select="'no'" as="xs:string"/>
  
  <xsl:template match="*" mode="split-uri">
    <!-- Override this in order to attach future split URIs to book-parts etc., as xml:base attributes.
      These base URIs will be used by store-chunks.xsl to generate chunks and XInclude instructions at the
    places where the chunks originated. 
    An override looks like
    <xsl:template match="book-part" mode="split-uri" as="attribute(xml:base)">
      <xsl:attribute name="xml:base" select="concat('out/', my:normalize-title(.), '.xml')"/>
    </xsl:template>
    This mode may be invoked from transforming @role in default mode or from invoking css:content 
    which results in transforming the element in mode class-att. 
    Also remember to add the following template to your importing XSLT(s): 
      <xsl:template match="*" mode="class-att" priority="2">
        <xsl:next-match/>
        <xsl:apply-templates select="." mode="split-uri"/>
      </xsl:template>
      <xsl:template match="@role" mode="default" priority="2">
        <xsl:next-match/>
        <xsl:apply-templates select=".." mode="split-uri"/>
      </xsl:template>
    -->
  </xsl:template>


  <xsl:function name="css:other-atts" as="attribute(*)*">
    <xsl:param name="context" as="element(*)"/>
    <xsl:sequence select="$context/@*[not(css:map-att-to-elt(., ..))]"/> 
  </xsl:function>

  <xsl:template name="css:remaining-atts">
    <xsl:param name="remaining-atts" as="attribute(*)*"/>
    <xsl:apply-templates select="$remaining-atts" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="@*" mode="hub2htm:css-style-overrides">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="*" mode="class-att"/>
  
  <xsl:variable name="dtd-version-att" as="attribute(dtd-version)">
    <xsl:attribute name="dtd-version" select="$dtd-version"/>
  </xsl:variable>

  <xsl:template match="* | @*" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="processing-instruction() | comment()" mode="default clean-up">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="/*" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- This anchor has already given its ID to someone else, but we've been
    too lazy to remove this anchor in the first run. -->
  <xsl:template match="target[if (count(root(.)/*) = 1)
                              then key('by-id', @id)/local-name() != 'target'
                              else false()
                             ]" mode="clean-up"/>
  
  <xsl:template match="sup[fn][every $c in node() satisfies $c/self::fn]" mode="clean-up">
    <!-- This has been necessitated by https://github.com/transpect/hub2html/commit/f2f09c (and parent commit). -->
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
 
  <xsl:template match="styled-content[every $att in @* satisfies $att/self::attribute(srcpath)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="styled-content[break]" mode="clean-up">
    <xsl:if test="break/following-sibling::node()[1][self::text()[matches(., '\S')]]">
      <xsl:apply-templates select="break" mode="#current"/>
    </xsl:if>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node() except break" mode="#current"/>
    </xsl:copy>
    <xsl:if test="break/preceding-sibling::node()[1][self::text()[matches(., '\S')]]">
      <xsl:apply-templates select="break" mode="#current"/>
    </xsl:if>
    <xsl:message select="'WARNING: PULLED break out of styled-content'"/>
  </xsl:template>
  
  <xsl:template match="styled-content[not(node())]" mode="clean-up" priority="2"/>

  <!-- no more breaks if several paras are in head! -->
  <xsl:template match="th/p[bold][every $n in node() satisfies ($n/self::bold)]" mode="clean-up">
    <xsl:apply-templates select="bold/node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="*[self::bold or self::italic][every $n in node() satisfies ($n/self::table-wrap or $n/self::target or $n/self::boxed-text)]" mode="clean-up" priority="6">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="th[p][count(p) eq 1][not(p/bold)]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="css:font-weight" select="'normal'"/>
      <xsl:apply-templates select="p/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="table[count(thead) gt 1]" mode="clean-up">
    <xsl:variable name="context" select="." as="element(table)"/>
    <xsl:for-each-group select="*" group-starting-with="thead">
      <xsl:for-each select="$context">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, current-group()" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:for-each-group>
  </xsl:template>
  

  <xsl:template match="body[not(following-sibling::back)][ref-list]" mode="clean-up">
    <xsl:next-match/>
    <back>
      <xsl:for-each select="ref-list">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </back>
  </xsl:template>

  <xsl:template match="body[not(following-sibling::back)]/ref-list" mode="clean-up"/>

  <xsl:template match="body[not(node())]" mode="clean-up"/>
  
  <xsl:template match="dbk:phrase[dbk:informaltable][every $n in node() satisfies ($n/self::dbk:informaltable)]" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p[not(parent::*[self::list-item or self::ack or self::*:th or self::*:td] or self::term)]
                        [boxed-text]
                        [every $n in node() satisfies ($n/self::boxed-text)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="boxed-text/title" mode="clean-up">
    <caption>
      <xsl:next-match/>
    </caption>
  </xsl:template>

  <xsl:template match="ack/boxed-text" mode="clean-up">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <!-- not permitted by schema: -->
  <xsl:template match="sub/@content-type | sup/@content-type" mode="clean-up"/>

  <xsl:template match="*:tabs" mode="clean-up">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>

  <!-- Preventing tabs to be eliminated without a space between -->
  <xsl:template match="*:tab" mode="clean-up">
    <xsl:choose>
      <xsl:when test="(preceding-sibling::node()[1][self::text()][matches(., '\S$')] and following-sibling::node()[1][self::text()][matches(., '^\S')]) or
                      (preceding-sibling::node()[1][matches(string-join(descendant-or-self::text(), ''), '\S$')] and following-sibling::node()[1][matches(string-join(descendant-or-self::text(), ''), '^\S')])">
        <xsl:text>&#160;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="p | title" mode="clean-up" priority="5">
    <xsl:param name="root" tunnel="yes" as="document-node(element(*))?"/>
    <xsl:variable name="actual-root" select="if ($root) then $root else root(current())"/>
    <xsl:variable name="p-atts" as="attribute(*)*" select="@*[matches(name(), '^(css:|xml:lang$)')]"/>
    <xsl:variable name="p-class-atts" as="attribute(*)*" 
      select="key(
                 'jats:style-by-type', 
                 (@style-type|@content-type), 
                 $actual-root
              )/(css:attic | .)/@*[matches(name(), '^(css:|xml:lang$)')]"/>
    <xsl:next-match>
      <xsl:with-param name="p-atts" tunnel="yes" as="attribute(*)*">
        <xsl:sequence select="$p-atts, $p-class-atts[not(name() = $p-atts/name())]"/>
      </xsl:with-param>
    </xsl:next-match>
  </xsl:template>
  
  <!-- Dissolve styled content whose css atts all went to the attic.
       Will lose srcpath attributes though. Solution: Adapt the srcpath message rendering mechanism 
       so that it uses ancestor paths if it doesn’t find an immediate matching element. -->
  <xsl:template match="styled-content[@style-type]
                                     [every $att in @* satisfies (name($att) = ('style-type', 'xml:id', 'srcpath'))]"
                mode="clean-up" priority="2">
    <xsl:param name="p-atts" as="attribute(*)*" tunnel="yes"/>
    <xsl:param name="root" as="document-node()?" tunnel="yes"/>
    <xsl:if test="@srcpath = 'Stories/Story_u8f7b7.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[1]/CharacterStyleRange[2]'"><xsl:message select="'####', string-join($p-atts, '')"/></xsl:if>
    <xsl:choose>
      <xsl:when test="exists($p-atts)">
        <xsl:variable name="style-atts" as="attribute(*)*"
          select="key('jats:style-by-type', @style-type, ($root, root(.))[1])/(css:attic | .)/@*[matches(name(), '^(css:|xml:lang$)')]"/>
        <xsl:variable name="differing-attributes" select="for $a 
                                                           in $style-atts
                                                       return $a[
                                                                  some $b in $p-atts[name() = name($a)] satisfies ($b != $a)
                                                                  or 
                                                                  empty($p-atts[name() = name($a)])
                                                                ]" as="attribute(*)*"/>
         <xsl:choose>
          <!-- Don’t dissolve spans if they override some para property (e.g., they make
               bold to normal by means of their style: -->
           <xsl:when test="exists($differing-attributes) and 
                           (every $child in node() satisfies name($child) != $differing-attributes)">
            <xsl:next-match/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates mode="#current">
              <xsl:with-param name="srcpath" select="@srcpath" tunnel="yes"/>
            </xsl:apply-templates>    
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- GI 2020-05-12: Was inclined to use <xsl:next-match/> here while fixing 
        https://redmine.le-tex.de/issues/8439 
        The I realized that the bold wrapping was deactivated in all titles. It shouldn’t
        be deactivated for figure and table titles because they aren’t bold by default. 
        Apart from that, it might be a bit overzealous to unwrap styled-content when $p-atts
        are empty. But keeping it like that for the time being.-->
        <xsl:apply-templates mode="#current">
          <xsl:with-param name="srcpath" select="@srcpath" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="styled-content[matches(@style-type, $jats:cstyle-whitelist-x, 'x')]" 
    mode="clean-up" priority="4">
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="@style-type"/>
      <xsl:apply-templates select="@* except @style-type, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:variable name="jats:cstyle-whitelist-x" as="xs:string"
    select="'(^Lit$|ch_blockade|ch_[uU]nderline)'"/>    
  
  <xsl:template match="styled-content"
                mode="clean-up" priority="3">
    <xsl:param name="root" as="document-node(element(*))" select="root()" tunnel="yes"/>
    <xsl:variable name="p" select="ancestor::*[name() = ('p', 'title')][1]" as="element(*)?"/>
    <xsl:choose>
      <!-- This condition would usually have appeared as a predicate of the matching pattern.
           Since we might process temporary trees in the adaptions, we need to be able to
           explicitly pass a root node to the key function. -->
      <xsl:when test="every $att in (key('jats:style-by-type', @style-type, $root)/(css:attic | .)/@*, @*) 
                      satisfies (
                                  name($att) = ('name', 'native-name', 'layout-type', 'srcpath', 'style-type')
                                  or 
                                  (@*[name() = name($att)], $att)[1]  = (
                                            $p/@*[name() = name($att)], 
                                            key('jats:style-by-type', $p/(@style-type|@content-type), $root)
                                              /(css:attic | .)/@*[name() = name($att)]
                                         )[1]
                                )">
        <xsl:apply-templates mode="#current">
          <xsl:with-param name="srcpath" select="@srcpath" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="styled-content/@*[matches(name(), '^(css:|xml:lang$)')]" mode="clean-up" priority="6">
    <xsl:variable name="p-ancestor" as="element(*)?" select="../ancestor::*[name() = ('p', 'title')][1]"/>
    <xsl:variable name="p-att" as="attribute(*)?" select="$p-ancestor/@*[name() = name(current())]"/>
    <xsl:variable name="p-style-att" as="attribute(*)*">
      <xsl:if test="count(root(..)/node()) = 1 and count(root(..)/*) = 1">
        <xsl:sequence select="key(
                                  'jats:style-by-type', 
                                  $p-ancestor/(@style-type|@content-type), 
                                  root(..)
                              )/(css:attic | .)/@*[name() = name(current())]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="styled-content-ancestor" as="element(styled-content)?" 
      select="../ancestor::styled-content[1][if ($p-ancestor) then exists(ancestor::* intersect $p-ancestor) else true()]"/>
    <xsl:variable name="styled-content-att" as="attribute(*)?" select="$styled-content-ancestor/@*[name() = name(current())]"/>
    <xsl:variable name="styled-content-ancestor-style-att" as="attribute(*)*">
      <xsl:if test="count(root(..)/node()) = 1 and count(root(..)/*) = 1">
        <xsl:sequence select="key(
                                  'jats:style-by-type', 
                                  $styled-content-ancestor/@style-type, 
                                  root(..)
                              )/(css:attic | .)/@*[name() = name(current())]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="count($p-style-att) gt 1">
      <xsl:message select="'More than one style with the same name (must not happen!) ', key(
                                  'jats:style-by-type', 
                                  ../ancestor::*[name() = ('p', 'title')][1]/(@style-type|@content-type), 
                                  root(..)
                              ), $p-style-att"/>
    </xsl:if>
    <xsl:if test="not(($styled-content-att, $styled-content-ancestor-style-att, $p-att, $p-style-att)[1] = .)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[name() = ('italic', 'bold', 'underline')]
                        [empty(@srcpath)]
                        [empty(*[name() = ('italic', 'bold', 'underline')])]" mode="clean-up" priority="4">
    <xsl:param name="srcpath" as="attribute(srcpath)?" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="$srcpath"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="italic[@css:font-style = 'normal']" mode="clean-up" priority="5">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="bold[@css:font-weight = 'normal']" mode="clean-up" priority="5">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:key name="jats:style-by-type" match="css:rule" use="@name" />

  <!--  no 'hub2bits: unhandled'-messages for MathML elements -->
  <xsl:template match="*[ancestor-or-self::mml:math]" mode="default" priority="-0.9">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="default" priority="-1">
    <xsl:message>hub2bits: unhandled in mode default: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
    <xsl:copy copy-namespaces="no">
      <xsl:call-template name="css:content"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*" mode="default" priority="-1.5">
    <xsl:copy/>
    <xsl:message>hub2bits: attr unhandled in mode default: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="mml:*/@* | @xml:space" mode="default">
    <xsl:copy/>
  </xsl:template>

  <!-- MOVE WRAP ATTS (italic, bold, underline) TO CSS RULE ATTIC -->
  
  <xsl:template match="css:rule[$css:wrap-content-with-elements-from-mappable-style-attributes]" mode="default">
     <xsl:call-template name="css:move-to-attic">
       <xsl:with-param name="atts" select="@*[css:map-att-to-elt(., key('css:styled-content', ../@name)[1])]"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="css:rule[$css:wrap-content-with-elements-from-mappable-style-attributes]
                               [not(key('css:styled-content', @name))]" mode="default" priority="2">
    <xsl:comment>
    <xsl:for-each select="@*">
      <xsl:sequence select="concat(name(), '=&quot;', ., '&quot;&#xa;')"/>
    </xsl:for-each>
    </xsl:comment>
  </xsl:template>
  
  <xsl:template match="css:rules | css:rules/@* | dbk:tabs | dbk:tab | dbk:tab/@* | dbk:linked-style | dbk:linked-style/@*" mode="default">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- DEFAULT ATTRIBUTE HANDLING -->

  <xsl:template match="@xml:id" mode="default">
    <xsl:attribute name="id" select="."/>
  </xsl:template>

  <xsl:template match="@role" mode="default">
    <xsl:param name="elt-name" as="xs:string?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$elt-name">
        <xsl:attribute name="book-part-type" select="."/>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="content-type" select="."/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select=".." mode="split-uri"/>
  </xsl:template>
  
  <xsl:template match="@tgroupstyle" mode="default">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>

  <xsl:key name="by-id" match="*[@id | @xml:id]" use="@id | @xml:id"/>
  
  <xsl:template match="@linkend | @linkends" mode="default">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="@linkend | @linkends" mode="clean-up">
    <xsl:param name="root" select="root()" as="document-node(element(*))" tunnel="yes"/>
    <xsl:variable name="targets" select="key('by-id', tokenize(., '\s+'), $root)" as="element(*)*"/>
    <xsl:variable name="types" select="jats:ref-types($targets)" as="xs:string*"/>
    <xsl:if test="count($types) eq 1">
      <xsl:attribute name="ref-type" select="$types[1]"/>
    </xsl:if>
    <xsl:attribute name="rid" select="."/>
  </xsl:template>

  <xsl:function name="jats:ref-types" as="xs:string*">
    <xsl:param name="targets" as="element(*)*"/>
    <xsl:variable name="names" select="distinct-values($targets/local-name())" as="xs:string*"/>
    <!-- distinct-values(): because of https://github.com/transpect/hub2bits/commit/22c9056,
      an ID will be created on ref, in addition to mixed-citation. This needs to be fixed
      eventually, so that IDs will only be created on ref. In the meantime, just make the
      two 'bibr' tokens unique. -->
    <xsl:sequence select="distinct-values(for $n in $names return jats:ref-type($n))"/>
  </xsl:function>
  
  <xsl:function name="jats:ref-type" as="xs:string?">
    <xsl:param name="elt-name" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$elt-name eq 'app'">
        <xsl:sequence select="'app'"/>
      </xsl:when>
      <xsl:when test="$elt-name = ('ref', 'mixed-citation', 'element-citation')">
        <xsl:sequence select="'bibr'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'boxed-text'">
        <xsl:sequence select="'boxed-text'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'disp-formula'">
        <xsl:sequence select="'disp-formula'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'fig'">
        <xsl:sequence select="'fig'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'fn'">
        <xsl:sequence select="'fn'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'sec'">
        <xsl:sequence select="'sec'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'table-wrap'">
        <xsl:sequence select="'table'"/>
      </xsl:when>
      <xsl:when test="$elt-name = 'book-part'">
        <xsl:sequence select="$elt-name"/>
      </xsl:when>
      <xsl:when test="$elt-name = 'index-term'"/>
      <xsl:otherwise>
        <xsl:message>hub2bits: unknown ref-type for <xsl:value-of select="$elt-name"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="@remap | @annotations" mode="default"/>

  <xsl:template match="@css:* | css:rule/@*" mode="default">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@xlink:href" mode="default">
    <xsl:copy/>
  </xsl:template>  
  
  <xsl:template match="@xml:lang" mode="default">
    <xsl:copy/>
  </xsl:template>  
  
  <xsl:template match="@srcpath[$srcpaths = 'yes']" mode="default" priority="2">
    <xsl:copy/>
  </xsl:template>  

  <xsl:template match="@srcpath[not($srcpaths = 'yes')]" mode="default" priority="2"/>
  
  <!-- STRUCTURE -->
  
  
  <xsl:function name="jats:matter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="name" select="$elt/local-name()" as="xs:string"/>
    <xsl:variable name="override" as="xs:string">
      <xsl:apply-templates select="$elt" mode="jats:matter"/>
    </xsl:variable>
    <!-- we could change this xsl:choose to an xsl:apply-templates in mode jats:matter if we create a template
      for each xsl:when case -->
    <xsl:choose>
      <xsl:when test="$override"><!-- empty string will be cast to false() -->
        <xsl:sequence select="$override"/>
      </xsl:when>
      <xsl:when test="$name = ('info', 'title', 'subtitle')"><xsl:sequence select="''"/></xsl:when>
      <xsl:when test="$name = 'acknowledgements' and (some $v in $jats:vocabulary satisfies $v = 'jats')"><xsl:sequence select="'back'"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface', 'partintro', 'acknowledgements', 'dedication', 'epigraph')"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:colophon[@role = ('front-matter-blurb', 'frontispiz', 'copyright-page', 'title-page', 'about-contrib', 'contrib-biographies', 'quotation', 'motto')]"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:glossary[preceding-sibling::*[1][jats:matter(.) = 'front-matter'] or following-sibling::*[1][jats:matter(.)  = 'front-matter']]"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:part[jats:is-appendix-part(.)]"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:when test="$name = ('part', 'chapter')"><xsl:sequence select="'book-body'"/></xsl:when>
      <xsl:when test="$name = ('appendix', 'index', 'glossary', 'bibliography', 'fn-group')"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  

  <!-- default: empty string, override this template as needed for specific contexts -->
  <xsl:template match="*" mode="jats:matter" as="xs:string">
    <xsl:sequence select="''"/>
  </xsl:template>
  
  <xsl:template match="dbk:book|dbk:hub" mode="default" priority="2">
    <book xmlns:css="http://www.w3.org/1996/css" xmlns:xlink="http://www.w3.org/1999/xlink">
      <xsl:copy-of select="@css:version"/>
      <xsl:attribute name="css:rule-selection-attribute" select="'content-type style-type'"/>
      <xsl:attribute name="source-dir-uri" select="dbk:info/dbk:keywordset[@role eq 'hub']/dbk:keyword[@role eq 'source-dir-uri']"/>      
      <xsl:sequence select="$dtd-version-att"/>
      <xsl:choose>
        <xsl:when test="@xml:lang">
          <xsl:copy-of select="@xml:lang"/>
        </xsl:when>
        <xsl:when test="key('jats:style-by-type', 'NormalParagraphStyle')[@xml:lang ne '']">
          <xsl:copy-of select="key('jats:style-by-type', 'NormalParagraphStyle')/@xml:lang, @xml:lang"/>
        </xsl:when>
      </xsl:choose>
      <xsl:call-template name="matter"/>
    </book>
  </xsl:template>

  <xsl:template name="matter">    
    <xsl:for-each-group select="*" group-adjacent="jats:matter(.)">
      <xsl:choose>
        <xsl:when test="current-grouping-key() ne ''">
          <xsl:element name="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="#current"/>
            <xsl:if test="current-grouping-key() eq 'book-back' and $jats:notes-type eq 'endnotes' and $jats:notes-per-chapter eq 'no'">
              <xsl:call-template name="endnotes">
                <xsl:with-param name="footnotes" as="element(dbk:footnote)*" select="//dbk:footnote"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="dbk:hub/dbk:info
                      |dbk:book/dbk:info" mode="default">
    <xsl:variable name="context" select="parent::*/local-name()" as="xs:string"/>
    <xsl:variable name="elts-for-grouping" as="element()*"
                  select="dbk:title, parent::*/dbk:title, 
                          dbk:subtitle, parent::*/dbk:subtitle,
                          dbk:titleabbrev, parent::*/dbk:titleabbrev,
                          dbk:authorgroup, dbk:author, dbk:editor, dbk:othercredit,
                          (dbk:copyright|dbk:legalnotice), dbk:bibliomisc, dbk:cover"/>
    <book-meta>
      <xsl:apply-templates select="@srcpath" mode="#current"/>
      <xsl:call-template name="title-info">
        <xsl:with-param name="elts" select="$elts-for-grouping"/>
        <xsl:with-param name="context" select="parent::*"/>
      </xsl:call-template>
      <xsl:apply-templates select="* except ($elts-for-grouping, css:rules, dbk:keywordset[@role = $kwd-group-keywordset-roles])" mode="#current"/>
      <xsl:call-template name="kwd-group"/>
      <xsl:call-template name="custom-meta-group"/>
    </book-meta>
  </xsl:template>
  
  <!-- bring metadata elements in a valid order -->
  
  <xsl:template match="article-meta|book-meta|book-part-meta|collection-meta|journal-meta|sec-meta" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*, jats:order-meta(*)" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- order children in element name -->
  <xsl:template match="name" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*, surname, given-names, prefix, suffix" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="kwd-group">
    <xsl:apply-templates select="dbk:keywordset[@role = $kwd-group-keywordset-roles]" mode="#current"/>
  </xsl:template>

  <xsl:template name="custom-meta-group">
    <custom-meta-group>
      <xsl:apply-templates select="css:rules" mode="#current"/>
    </custom-meta-group>
  </xsl:template>
  
  <xsl:template match="dbk:biblioid" mode="default">
    <book-id>
      <xsl:apply-templates select="@class, @role, node()" mode="#current"/>
    </book-id>
  </xsl:template>

  <xsl:template match="dbk:biblioid[matches((@class, @role)[1], '^doi$', 'i')]" mode="default">
    <pub-id>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </pub-id>
  </xsl:template>

  <xsl:template match="dbk:biblioid/@*[local-name() = ('class', 'role')][matches(., '^doi$', 'i')]" mode="default">
    <xsl:attribute name="pub-id-type" select="'doi'"/>
  </xsl:template>

  <xsl:template match="dbk:biblioid[@class = 'doi']/@role" mode="default"/>
  
  <xsl:template match="dbk:biblioid[matches((@class, @role)[1], '^issn$', 'i')]" mode="default">
    <issn>
      <xsl:apply-templates select="@* except (@class, @role), node()" mode="#current"/>
    </issn>
  </xsl:template>
  
  <xsl:template match="dbk:biblioid[matches((@class, @role)[1], '^isbn$', 'i')]" mode="default">
    <isbn>
      <xsl:apply-templates select="@* except (@class, @role), node()" mode="#current"/>
    </isbn>
  </xsl:template>

  <xsl:template match="dbk:biblioid/@*[name() = ('role', 'class')]" mode="default" priority="-1">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>
  <xsl:template match="dbk:biblioid[@class]/@role" mode="default"/>

  <xsl:variable name="kwd-group-keywordset-roles" as="xs:string*"
    select="('author-created', 'author-generated', 'abbreviations')"/>

  <xsl:template match="dbk:keywordset[not(@role = $kwd-group-keywordset-roles)]" mode="default">
    <custom-meta-group>
      <xsl:apply-templates mode="#current"/>
    </custom-meta-group>
  </xsl:template>

  <xsl:template match="dbk:keywordset[@role = $kwd-group-keywordset-roles]" mode="default" priority="1">
    <kwd-group>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </kwd-group>
  </xsl:template>

  <xsl:template match="dbk:keywordset[@role = $kwd-group-keywordset-roles]/@annotations" mode="default">
    <title>
      <xsl:value-of select="."/>
    </title>
  </xsl:template>

  <xsl:template match="dbk:keywordset/@role[. = $kwd-group-keywordset-roles]" mode="default">
    <xsl:attribute name="kwd-group-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:keywordset[@role = $kwd-group-keywordset-roles]/dbk:keyword" mode="default">
    <kwd>
      <xsl:apply-templates mode="#current"/>
    </kwd>
  </xsl:template>
  
  <xsl:template match="dbk:keywordset[not(@role = $kwd-group-keywordset-roles)]/dbk:keyword" mode="default">
    <custom-meta>
      <meta-name>
        <xsl:value-of select="@role"/>
      </meta-name>
      <meta-value>
        <xsl:value-of select="."/>
      </meta-value>
    </custom-meta>
  </xsl:template>
  
  <xsl:template match="dbk:authorgroup" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:author
                      |dbk:editor
                      |dbk:othercredit" mode="default">
    <contrib contrib-type="{local-name()}">
      <xsl:call-template name="css:content"/>
    </contrib>
  </xsl:template>
  
  <xsl:template match="dbk:biblioset/dbk:author
                      |dbk:biblioset/dbk:editor
                      |dbk:biblioset/dbk:othercredit" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="contrib/@content-type" mode="clean-up">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:bibliography//dbk:editor[count(node[normalize-space()]) = 1][dbk:orgname]" mode="default">
    <institution content-type="editor">
      <xsl:apply-templates select="@*, dbk:orgname/(@*, node())" mode="#current"/>
    </institution>
  </xsl:template>
  
  <xsl:template match="dbk:personname" mode="default">
    <xsl:choose>
      <xsl:when test="dbk:firstname|dbk:surname">
        <name>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:apply-templates select="dbk:surname" mode="#current"/>
          <xsl:if test="exists(dbk:firstname)">
            <given-names>
              <xsl:apply-templates select="dbk:firstname/@*" mode="#current"/>
              <xsl:for-each select="dbk:firstname">
                <xsl:apply-templates mode="#current"/>
                <xsl:if test="not(position() = last())">
                  <xsl:text> </xsl:text>
                </xsl:if>
              </xsl:for-each>
            </given-names>
          </xsl:if>
          <xsl:apply-templates select="*[not(self::dbk:surname|self::dbk:firstname)]" mode="#current"/>
        </name>    
      </xsl:when>
      <xsl:otherwise>
        <string-name><xsl:call-template name="css:content"/></string-name>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dbk:personname/dbk:honorific" mode="default">
    <prefix>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </prefix>
  </xsl:template>
  
  <xsl:template match="dbk:personname[dbk:surname]/dbk:lineage" mode="default">
    <suffix>
      <xsl:apply-templates mode="#current"/>
    </suffix>
  </xsl:template>
  
  <xsl:template match="contrib/string-name[empty(parent::name-alternatives)]
                                          [ancestor::article[1]/@dtd-version/xs:decimal(.) &lt; 1.2]
                                          [some $v in $jats:vocabulary satisfies ($v = 'jats')]
                                          [every $v in $jats:vocabulary satisfies (not($v = ('archiving', 'articleauthoring')))]" mode="clean-up">
    <!-- may not be contained in contrib in publishing tag set until v. 1.2-->
    <!-- best practice would be to use option <p:with-option name="vocab" select="'jats publishing'"/> on step hub2bits if name-alternatives should be generated.
      For backwards compatibility archiving is not set as default, so this template will come into action if option is not set or is set to "jats" only. -->
    <name-alternatives>
      <xsl:next-match/>
    </name-alternatives>
  </xsl:template>
  
  <xsl:template match="dbk:firstname" mode="default">
    <given-names>
      <xsl:call-template name="css:content"/>  
    </given-names>
  </xsl:template>
  
  <xsl:template match="dbk:othername" mode="default">
    <string-name>
      <!-- perhaps mapped to something else? string-name is for unstructured content in contrib -->
      <xsl:apply-templates select="text()" mode="#current"/>  
    </string-name>
  </xsl:template>
  
  <xsl:template match="dbk:volumenum" mode="default">
    <book-volume-number>
      <xsl:apply-templates mode="#current"/>
    </book-volume-number>
  </xsl:template>  
  
  <xsl:template match="dbk:edition" mode="default">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:surname" mode="default">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:authorgroup" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:authorgroup/dbk:*[local-name() = ('author', 'editor')]" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:*[local-name() = ('author', 'editor')]/dbk:personname" mode="default">
    <xsl:choose>
      <xsl:when test="dbk:firstname|dbk:surname">
        <name content-type="{parent::*/name()}">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </name>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:publisher" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:info/dbk:publisher" mode="default">
    <publisher>
      <xsl:apply-templates mode="#current"/>
    </publisher>
  </xsl:template>

  <xsl:template match="dbk:publishername" mode="default">
    <publisher-name>
      <xsl:apply-templates mode="#current"/>
    </publisher-name>
  </xsl:template>
  
  <xsl:template match="dbk:publisher/dbk:address" mode="default">
    <publisher-loc>
      <xsl:apply-templates mode="#current"/>
    </publisher-loc>
  </xsl:template>
  
  <xsl:template match="dbk:copyright" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:copyright/dbk:year" mode="default">
    <copyright-year>
      <xsl:apply-templates mode="#current"/>  
    </copyright-year>
  </xsl:template>
  
  <xsl:template match="dbk:copyright/dbk:holder" mode="default">
    <copyright-holder>
      <xsl:apply-templates mode="#current"/>
    </copyright-holder>
  </xsl:template>
  
  <xsl:template match="dbk:legalnotice" mode="default">
    <copyright-statement>
      <xsl:apply-templates select="*/node()" mode="#current"/>
    </copyright-statement>
  </xsl:template>
    
  <xsl:template match="dbk:org" mode="default" priority="2">
    <institution-wrap>
      <xsl:apply-templates select="@*, dbk:orgname" mode="#current"/>
    </institution-wrap>
    <xsl:apply-templates select="* except dbk:orgname" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:orgname" mode="default" priority="2">
    <institution>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </institution>
  </xsl:template>

  <xsl:template match="dbk:affiliation" mode="default" priority="2">
    <aff>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </aff>
  </xsl:template>
  
  <xsl:template match="dbk:personblurb" mode="default" priority="2">
    <bio>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </bio>
  </xsl:template>
  
  <xsl:template match="dbk:pubdate" mode="default">
    <xsl:element name="{if(ancestor::dbk:bibliography) then 'date' else 'pub-date'}">
      <xsl:choose>
        <xsl:when test="(some $v in $jats:vocabulary satisfies $v = 'jats') and 
                        (@role = 'year' or matches(., '^(19|20)\d\d$'))">
          <year>
            <xsl:apply-templates mode="#current"/>
          </year>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test=". castable as xs:date">
            <xsl:attribute name="iso-8601-date" select="xs:date(.)"/>
          </xsl:if>
          <string-date>
            <xsl:apply-templates mode="#current"/>
          </string-date>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:toc" mode="default">
    <toc>
      <xsl:apply-templates select="." mode="toc-depth"/>
      <xsl:call-template name="css:content"/>
    </toc>
  </xsl:template>
  

  <xsl:template match="dbk:toc/dbk:title
                      |dbk:index/dbk:title" mode="default" priority="2">
    <xsl:choose>
      <xsl:when test="xs:integer(jats:dtd-version()[1]) ge 2">
        <xsl:element name="{concat(parent::*/local-name(), '-title-group')}">
          <xsl:next-match/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <title-group>
          <xsl:next-match/>
        </title-group>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:toc" mode="toc-depth">
    <xsl:attribute name="depth" select="'3'"/>
  </xsl:template>

  <xsl:template match="dbk:section | dbk:sect1 | dbk:sect2 | dbk:sect3 | dbk:sect4 | dbk:sect5" mode="default">
    <sec><xsl:call-template name="css:content"/></sec>
  </xsl:template>
  
  <xsl:template match="@renderas" mode="default">
    <xsl:attribute name="disp-level" select="."/>
  </xsl:template>

  <xsl:template match="dbk:appendix" mode="default">
    <xsl:choose>
      <xsl:when test="jats:matter(.) = 'front-matter'">
        <front-matter-part>
          <xsl:apply-templates select="." mode="split-uri"/>
          <xsl:apply-templates select="@*" mode="#current"/>
          <book-part-meta>
            <title-group>
              <xsl:apply-templates select="(. | dbk:info)/(dbk:title | dbk:titleabbrev)" mode="#current"/>
            </title-group>
            <xsl:apply-templates select="dbk:info/(* except (dbk:title | dbk:titleabbrev))" mode="#current"/>
          </book-part-meta>
          <named-book-part-body>
            <xsl:apply-templates select="node() except (dbk:title | dbk:titleabbrev | dbk:info)" mode="#current">
              <xsl:with-param name="create-xref-for-footnotes" select="$jats:notes-type eq 'endnotes'" as="xs:boolean?" tunnel="yes"/>
            </xsl:apply-templates>
          </named-book-part-body>
        </front-matter-part>
      </xsl:when>
      <xsl:otherwise>
        <app>
          <xsl:apply-templates select="." mode="split-uri"/>
          <xsl:apply-templates select="@*, node()" mode="#current">
            <xsl:with-param name="create-xref-for-footnotes" select="$jats:notes-type eq 'endnotes'" as="xs:boolean?" tunnel="yes"/>
          </xsl:apply-templates>
        </app>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:appendix[jats:matter(.) = 'front-matter']/@role" mode="default">
    <xsl:attribute name="book-part-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:acknowledgements | dbk:preface[@role = 'acknowledgements']" mode="default">
    <ack><xsl:call-template name="css:content"/></ack>
  </xsl:template>
  
  <xsl:template match="dbk:preface[@role = 'acknowledgements']/@role" mode="default" priority="2"/>

  <xsl:template match="dbk:glossary" mode="default">
    <xsl:choose>
      <xsl:when test="ancestor::*/self::dbk:part[jats:is-appendix-part(.)] and not(parent::*[self::dbk:appendix|self::dbk:glossary])">
        <app>
          <xsl:apply-templates select="." mode="split-uri"/>
          <glossary>
            <xsl:call-template name="collect-glossary"/>
          </glossary>
        </app>
      </xsl:when>
      <xsl:otherwise>
        <glossary>
          <xsl:apply-templates select="." mode="split-uri"/>
          <xsl:call-template name="collect-glossary"/>
        </glossary>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="collect-glossary">
    <xsl:choose>
      <xsl:when test="exists (dbk:glossentry)
                      and
                      (every $n in (* except (dbk:title | dbk:info)) satisfies ($n/self::dbk:glossentry))">
        <xsl:apply-templates select="@*, dbk:title | dbk:info" mode="#current"/>
        <def-list>
          <xsl:apply-templates select="node() except (dbk:title | dbk:info)" mode="#current"/>
        </def-list>
      </xsl:when>
      <xsl:otherwise>
        <!-- This order (process info last – why is that?) was already like this in the template above 
          when GI introduced this named template -->
        <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dbk:glosslist" mode="default" priority="2">
    <def-list list-type="gloss-list">
      <xsl:call-template name="css:content"/>
    </def-list>
  </xsl:template>
  
  <xsl:template match="dbk:glossentry" mode="default">
    <def-item>
      <xsl:call-template name="css:content"/>
    </def-item>
  </xsl:template>

  <xsl:template match="dbk:glossterm" mode="default">
    <term>
      <xsl:call-template name="css:content"/>
    </term>
  </xsl:template>

  <xsl:template match="dbk:glossterm/@role" mode="default"/>
    
  <xsl:template match="dbk:glossdef" mode="default">
    <def>
      <xsl:call-template name="css:content"/>
    </def>
  </xsl:template>

  <xsl:variable name="use-static-index" select="false()"/>
  
  <xsl:template match="dbk:index" mode="default">
    <index>
      <xsl:apply-templates select="." mode="split-uri"/>
      <xsl:apply-templates select="@*, dbk:title" mode="#current"/>
      <xsl:choose>
        <xsl:when test="$use-static-index">
          <xsl:apply-templates mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
        <!-- will be filled in clean-up -->
        </xsl:otherwise>
      </xsl:choose>
    </index>
  </xsl:template>

  <xsl:function name="jats:book-part" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
<!--      <xsl:when test="$elt/self::dbk:part[jats:is-appendix-part(.)]"><xsl:sequence select="'app-group'"/></xsl:when>-->
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'book-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:partintro
                    | $elt/self::dbk:appendix[jats:matter(.) = 'front-matter']
                    | $elt/self::dbk:colophon[@role = ('front-matter-blurb', 'title-page', 'copyright-page', 'frontispiz', 
                                                       'about-contrib', 'contrib-biographies', 'motto', 'quotation')]">
        <xsl:sequence select="'front-matter-part'"/>
      </xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'foreword')]"><xsl:sequence select="'foreword'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'acknowledgements')]"><xsl:sequence select="'ack'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'praise')]"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:epigraph"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[@role = ('lot', 'lof', 'lob')]"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface"><xsl:sequence select="'preface'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:dedication"><xsl:sequence select="'dedication'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:acknowledgements"><xsl:sequence select="'ack'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:glossary"><xsl:sequence select="'glossary'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:index"><xsl:sequence select="'index'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'unknown-book-part'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="jats:is-appendix-part" as="xs:boolean">
    <xsl:param name="elt" as="element(dbk:part)"/>
    <xsl:sequence select="if ($jats:appendix-to-bookpart) 
                          then false() 
                          else (every $c in $elt/* 
                                satisfies $c/name() = ('appendix', 'index', 'bibliography', 'glossary', 
                                                       'title', 'subtitle', 'info'))"/>
  </xsl:function>

  <xsl:function name="jats:book-part-body" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="local-name($elt) = ('preface', 'partintro', 'dedication', 'preface', 'colophon','epigraph')"><xsl:sequence select="'named-book-part-body'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="concat('unknown-book-part-body_', $elt/name())"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:variable name="jats:additional-backmatter-parts-title-role-regex" as="xs:string" select="'(p_h_sec[12]_back)'"/>

  <xsl:function name="jats:part-submatter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:apply-templates select="$elt" mode="jats:part-submatter"/>
  </xsl:function>
  
  <!-- This function’s body was refactored from a monolithic xsl:choose to the folliwing templates. 
    The main motivation was to support custom meta elements that were allowed in the DocBook source,
    like this:
    <xsl:template match="dbk:chapter/dbk:info/rdf:Description" mode="jats:part-submatter" as="xs:string">
      <xsl:sequence select="'book-part-meta'"/>
    </xsl:template> -->
  
  <!-- additional advantage over xsl:choose in the function body with test="name($elt) = ('title', …)": 
       all the flexibility of matching patterns -->
  <xsl:template match="dbk:title | dbk:info | dbk:subtitle | dbk:titleabbrev" mode="jats:part-submatter" as="xs:string">
    <xsl:sequence select="'book-part-meta'"/>
  </xsl:template>
  
  <!-- this way, we can handle front matter appendices quite elegantly: --> 
  <xsl:template match="dbk:toc | dbk:appendix[following-sibling::dbk:chapter | following-sibling::dbk:part] | dbk:epigraph" 
    mode="jats:part-submatter" as="xs:string">
    <xsl:sequence select="'front-matter'"/>
  </xsl:template>
  
  <xsl:template match="dbk:bibliography | dbk:glossary | dbk:appendix | dbk:index |  dbk:preface[@role = 'acknowledgements'][preceding-sibling::*[self::dbk:appendix | self::dbk:chapter |  self::dbk:part | self::dbk:bibliography | self::dbk:index]] |
                       dbk:section[matches(dbk:title/@role, $jats:additional-backmatter-parts-title-role-regex)]" 
                mode="jats:part-submatter" as="xs:string">
    <xsl:sequence select="'back'"/>
  </xsl:template>
  
  <!-- previously xsl:otherwise: -->
  <xsl:template match="*" mode="jats:part-submatter" as="xs:string">
    <xsl:sequence select="jats:book-part-body(..)"/>
  </xsl:template>
  
  
  <xsl:function name="jats:order-meta" as="element()*">
    <xsl:param name="seq" as="element()*"/>
    <xsl:for-each select="$seq">
      <xsl:sort select="jats:get-meta-order-int(.)"/>
      <xsl:sequence select="."/>
    </xsl:for-each>
  </xsl:function>
  
  <xsl:function name="jats:get-meta-order-int" as="xs:integer">
    <xsl:param name="elt" as="element()"/>
    <xsl:apply-templates select="$elt" mode="meta-order"/>
  </xsl:function> 
  
  <xsl:template match="article-id | book-id | journal-id | book-part-id | collection-id" mode="meta-order" as="xs:integer">
    <xsl:sequence select="1"/>
  </xsl:template>
  <xsl:template match="article-categories | subj-group" mode="meta-order" as="xs:integer">
    <xsl:sequence select="2"/>
  </xsl:template>
  <xsl:template match="book-title-group | journal-title-group | title-group" mode="meta-order" as="xs:integer">                  
    <xsl:sequence select="3"/> 
  </xsl:template>
  <xsl:template match="contrib-group| aff | aff-alternatives" mode="meta-order" as="xs:integer">               
    <xsl:sequence select="4"/> 
  </xsl:template>
  <xsl:template match="author-notes" mode="meta-order" as="xs:integer">
    <xsl:sequence select="5"/>
  </xsl:template>
  <xsl:template match="pub-date" mode="meta-order" as="xs:integer">
    <xsl:sequence select="6"/>
  </xsl:template>
  <xsl:template match="subj-group" mode="meta-order" as="xs:integer">
    <xsl:sequence select="2"/>
  </xsl:template>
  <xsl:template match="book-volume-number | volume" mode="meta-order" as="xs:integer">
    <xsl:sequence select="7"/>
  </xsl:template>
  <xsl:template match="book-volume-id | volume-id" mode="meta-order" as="xs:integer">
    <xsl:sequence select="8"/>
  </xsl:template> 
  <xsl:template match="issue | issn" mode="meta-order" as="xs:integer">
    <xsl:sequence select="9"/>
  </xsl:template> 
  <xsl:template match="issn-l" mode="meta-order" as="xs:integer">
    <xsl:sequence select="10"/>
  </xsl:template>
  <xsl:template match="isbn" mode="meta-order" as="xs:integer">
    <xsl:sequence select="11"/>
  </xsl:template>
  <xsl:template match="publisher" mode="meta-order" as="xs:integer">
    <xsl:sequence select="12"/>
  </xsl:template>
  <xsl:template match="fpage" mode="meta-order" as="xs:integer">
    <xsl:sequence select="13"/>
  </xsl:template>
  <xsl:template match="lpage" mode="meta-order" as="xs:integer">
    <xsl:sequence select="13"/>
  </xsl:template>
  <xsl:template match="edition" mode="meta-order" as="xs:integer">
    <xsl:sequence select="14"/>
  </xsl:template>
  <xsl:template match="supplementary-material" mode="meta-order" as="xs:integer">
    <xsl:sequence select="15"/>
  </xsl:template>
  <xsl:template match="pub-history" mode="meta-order" as="xs:integer">
    <xsl:sequence select="16"/>
  </xsl:template>
  <xsl:template match="permissions" mode="meta-order" as="xs:integer">
    <xsl:sequence select="17"/>
  </xsl:template>
  <xsl:template match="self-uri" mode="meta-order" as="xs:integer">
    <xsl:sequence select="18"/>
  </xsl:template>
  <xsl:template match="related-article | related-object" mode="meta-order" as="xs:integer">
    <xsl:sequence select="19"/>
  </xsl:template>
  <xsl:template match="abstract" mode="meta-order" as="xs:integer">
    <xsl:sequence select="20"/>
  </xsl:template>
  <xsl:template match="trans-abstract" mode="meta-order" as="xs:integer">
    <xsl:sequence select="21"/>
  </xsl:template>
  <xsl:template match="kwd-group" mode="meta-order" as="xs:integer">
    <xsl:sequence select="22"/>
  </xsl:template>
  <xsl:template match="funding-group" mode="meta-order" as="xs:integer">
    <xsl:sequence select="23"/>
  </xsl:template>
  <xsl:template match="conference" mode="meta-order" as="xs:integer">
    <xsl:sequence select="24"/>
  </xsl:template>
  <xsl:template match="counts" mode="meta-order" as="xs:integer">
    <xsl:sequence select="25"/>
  </xsl:template>
  <xsl:template match="custom-meta-group" mode="meta-order" as="xs:integer">
    <xsl:sequence select="26"/>
  </xsl:template>
  <xsl:template match="notes" mode="meta-order" as="xs:integer">
    <xsl:sequence select="27"/>
  </xsl:template>
  <xsl:template match="node()" mode="meta-order" as="xs:integer" priority="-1">
    <xsl:sequence select="100"/>
  </xsl:template>

  <xsl:template match="article-meta/*" mode="meta-order" as="xs:integer">
    <xsl:sequence 
      select="index-of(
                (
                  'article-id', 'article-version', 'article-version-alternatives', 
                  'article-categories', 'title-group', 'contrib-group', 'aff', 
                  'aff-alternatives', 'author-notes', 'pub-date', 'pub-date-not-available', 
                  'volume', 'volume-id', 'volume-series', 'issue', 'issue-id', 
                  'issue-title', 'issue-sponsor', 'issue-part', 'volume-issue-group', 
                  'isbn', 'supplement', 'fpage', 'lpage', 'page-range', 'elocation-id', 
                  'email', 'ext-link', 'uri', 'product', 'supplementary-material', 
                  'history', 'pub-history', 'permissions', 'self-uri', 'related-article', 
                  'related-object', 'abstract', 'trans-abstract', 'kwd-group', 
                  'funding-group', 'support-group', 'conference', 'counts', 'custom-meta-group'
                ), name()
              )"/>
  </xsl:template>

  <xsl:template match="dbk:part[jats:is-appendix-part(.)][not(dbk:index)]" mode="default">
    <app-group>
      <xsl:apply-templates select="." mode="split-uri"/>
      <xsl:call-template name="css:content"/>
    </app-group>
  </xsl:template>
  
  <xsl:template match="app-group" mode="clean-up">
    <xsl:element name="{if(parent::book-back and xs:integer(jats:dtd-version()[1]) &gt;= 2) then 'book-app-group' else 'app-group'}">
      <xsl:apply-templates select="@*, node() except (ref-list | app)" mode="#current"/>
      <xsl:apply-templates select="app | ref-list" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="book-back/app[xs:integer(jats:dtd-version()[1]) &gt;= 2]" mode="clean-up">
    <book-app>
      <xsl:apply-templates select="@*" mode="#current"/>
      <book-part-meta>
        <title-group>
          <xsl:apply-templates select="label, title" mode="#current"/>
        </title-group>
      </book-part-meta>
      <xsl:element name="{if (ref-list) then 'back' else 'body'}">
        <xsl:apply-templates select="node() except (label,title)" mode="#current"/>
      </xsl:element>
    </book-app>
  </xsl:template>
  
  <xsl:template match="  dbk:part | dbk:part[jats:is-appendix-part(.)][dbk:index] | dbk:chapter | dbk:preface[not(@role = 'acknowledgements')] 
                       | dbk:partintro | dbk:colophon | dbk:dedication | dbk:epigraph[not(parent::dbk:info[parent::dbk:section])]" mode="default">
    <xsl:variable name="elt-name" as="xs:string" select="jats:book-part(.)"/>
    <xsl:element name="{$elt-name}">
      <xsl:apply-templates select="." mode="split-uri"/>
      <xsl:if test="$elt-name eq 'book-part'">
        <xsl:attribute name="book-part-type" select="local-name()"/>
        <!-- may be overwritten by transforming @role -->
      </xsl:if>
      <xsl:apply-templates select="@*" mode="#current">
        <xsl:with-param name="elt-name" select="$elt-name" tunnel="yes"/>
      </xsl:apply-templates>
      <xsl:variable name="context" select="." as="element(*)"/>
      <xsl:variable name="grouped-matter-parts" as="element()*">
        <xsl:for-each-group select="*" group-adjacent="jats:part-submatter(.)">
        <xsl:element name="{current-grouping-key()}">
          <xsl:choose>
            <xsl:when test="matches(current-grouping-key(), 'meta')">
              <xsl:call-template name="title-info">
                <xsl:with-param name="elts" 
                                select="current-group()/(self::dbk:title|self::dbk:info/* except dbk:epigraph |self::dbk:subtitle|self::dbk:titleabbrev|self::dbk:bibliomisc)"/>
                <xsl:with-param name="context" select="parent::*"/>
                <xsl:with-param name="create-xref-for-footnotes" select="$jats:notes-type eq 'endnotes'" as="xs:boolean?" tunnel="yes"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current">
                <xsl:with-param name="create-xref-for-footnotes" select="$jats:notes-type eq 'endnotes'" as="xs:boolean?" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$context[not(self::dbk:part[dbk:chapter])]
                         and $jats:notes-type eq 'endnotes' and $jats:notes-per-chapter eq 'yes'
                         and current-grouping-key() = 'back'">
            <xsl:call-template name="endnotes">
              <xsl:with-param name="footnotes" select=".//dbk:footnote" as="element(dbk:footnote)*"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:element>
        <xsl:if test="current-group()/self::dbk:info/dbk:epigraph">
          <xsl:for-each-group select="current-group()/self::dbk:info/dbk:epigraph" group-adjacent="jats:part-submatter(.)">
            <xsl:element name="{current-grouping-key()}">
             <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:element>
          </xsl:for-each-group>
        </xsl:if>
      </xsl:for-each-group>
      </xsl:variable>
      <xsl:sequence select="$grouped-matter-parts"/>
      <xsl:if test="(not(self::dbk:part[dbk:chapter]))
                    and $jats:notes-type eq 'endnotes' and $jats:notes-per-chapter eq 'yes'
                    and not($grouped-matter-parts[self::*:back])
                    and exists(.//dbk:footnote)">
        <back>   
          <xsl:call-template name="endnotes">
            <xsl:with-param name="footnotes" select=".//dbk:footnote" as="element(dbk:footnote)*"/>
          </xsl:call-template>
        </back>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:epigraph[parent::dbk:info[parent::dbk:section]]" mode="default">
    <disp-quote>
      <xsl:call-template name="css:content"/>
    </disp-quote>
  </xsl:template>
  
  <xsl:template name="endnotes">
    <xsl:param name="footnotes" as="element(dbk:footnote)*"/>
    <xsl:if test="exists($footnotes)">
      <fn-group>
        <xsl:apply-templates select="$footnotes" mode="#current">
          <xsl:with-param name="create-xref-for-footnotes" select="false()" as="xs:boolean?" tunnel="yes"/>
        </xsl:apply-templates>
      </fn-group>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@renderas[not(parent::dbk:section)]" mode="default"/>
  <xsl:template match="dbk:preface/@role" mode="default">
    <xsl:attribute name="book-part-type" select="."/>
  </xsl:template>
  
  <!-- METADATA -->

  <xsl:function name="jats:meta-component" as="xs:string+">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="context" as="element()?"/>
    <xsl:apply-templates select="$elt" mode="jats:meta-component">
      <xsl:with-param name="context" select="$context"/>
    </xsl:apply-templates>
  </xsl:function>
  
  <xsl:template match="*" mode="jats:meta-component">
    <xsl:sequence select="concat('unknown-meta_', name())"/>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc | dbk:cover" mode="jats:meta-component" as="xs:string">
    <xsl:sequence select="'custom-meta-group'"/>
  </xsl:template>
  
  <xsl:template match="dbk:legalnotice | dbk:copyright" mode="jats:meta-component" as="xs:string">
    <xsl:sequence select="'permissions'"/>
  </xsl:template>
  
  <xsl:template match="dbk:abstract" mode="jats:meta-component" as="xs:string">
    <xsl:sequence select="'abstract'"/>
  </xsl:template>
  
  <xsl:template match="dbk:authorgroup
                      |dbk:author[not(parent::dbk:authorgroup)]
                      |dbk:editor[not(parent::dbk:authorgroup)]
                      |dbk:othercredit[not(parent::dbk:authorgroup)]" mode="jats:meta-component" as="xs:string">
    <xsl:sequence select="'contrib-group'"/>
  </xsl:template>
  
  <xsl:template match="dbk:keywordset" mode="jats:meta-component" as="xs:string">
    <xsl:sequence select="'kwd-group'"/>
  </xsl:template>
  
  <xsl:template match="dbk:title | dbk:subtitle | dbk:titleabbrev" mode="jats:meta-component" as="xs:string">
    <!-- Probably can do without passing $context as a parameter, by simply matching book/title etc.
      with higher priority? Leave it as it is for now because a) who knows which customization uses the 
    2-argument function and b) spelling out all matching patterns might be more verbose than the following: -->
    <xsl:param name="context" as="element(*)?"/>
    <xsl:choose>
      <xsl:when test="$context/local-name() = ('book', 'hub')">
        <xsl:sequence select="'book-title-group'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'title-group'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="title-info" as="node()*">
    <xsl:param name="elts" as="element(*)*"/>
    <xsl:param name="context" as="element()?"/>
    <xsl:for-each-group select="$elts" group-by="jats:meta-component(., $context)">
      <xsl:choose>
        <xsl:when test="current-grouping-key() = ('abstract', '','kwd-group')">
          <xsl:apply-templates select="current-group()" mode="#current">
            <xsl:with-param name="create-xref-for-footnotes" select="$jats:notes-type eq 'endnotes'" as="xs:boolean?" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="{current-grouping-key()}" namespace="">
            <xsl:apply-templates select="current-group()" mode="#current">
              <xsl:with-param name="create-xref-for-footnotes" select="$jats:notes-type eq 'endnotes'" as="xs:boolean?" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="dbk:info" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="*[self::dbk:section
                        |self::dbk:acknowledgements
                        |self::dbk:preface[@role = 'acknowledgements']]/dbk:info[dbk:title][count(*) gt 1]
                                                                                [dbk:author | dbk:authorgroup | dbk:abstract[not(parent::dbk:biblioentry)] | dbk:keywordset | dbk:legalnotice | dbk:copyright]  
                      | dbk:appendix/dbk:info[dbk:title][dbk:author | dbk:authorgroup | dbk:abstract[not(parent::dbk:biblioentry)] | dbk:keywordset | dbk:legalnotice | dbk:copyright]" mode="default" priority="2">
    <sec-meta>
      <xsl:apply-templates select="dbk:authorgroup | dbk:author | dbk:abstract | dbk:keywordset | dbk:legalnotice | dbk:copyright" mode="#current"/>
    </sec-meta>
    <xsl:apply-templates select="dbk:title, dbk:subtitle, dbk:titleabbrev" mode="#current"/>
  </xsl:template>

  <xsl:template match="*[   self::dbk:*[local-name() = ('section', 'appendix', 'acknowledgements')] 
                         or self::dbk:preface[@role = 'acknowledgements']]/dbk:info/dbk:*[local-name() = ('author', 'editor', 'othercredit')]" mode="default" priority="3">
    <contrib-group>
      <xsl:next-match/>
    </contrib-group>
  </xsl:template>
  
  <xsl:template match="dbk:book/dbk:title|dbk:book/dbk:info/dbk:title" mode="default" priority="5">
    <book-title>
      <xsl:apply-templates  select="@xml:id, @xml:base, node(), ../dbk:itermset/*, ../dbk:info/dbk:itermset/*" mode="#current"/>
    </book-title>
  </xsl:template> 
   
  <xsl:template match="dbk:subtitle" mode="default">
    <subtitle>
      <xsl:call-template name="css:content"/>
    </subtitle>
  </xsl:template>
  
  <xsl:template match="dbk:titleabbrev" mode="default">
    <alt-title>
      <xsl:call-template name="css:content"/>
    </alt-title>
  </xsl:template>
  
  <xsl:template match="dbk:subtitle/dbk:date" mode="default">
    <named-content content-type="edition">
      <xsl:call-template name="css:content"/>
    </named-content>
  </xsl:template> 
  
  <xsl:template match="dbk:abstract[not(parent::dbk:biblioentry)]" mode="default">
    <abstract>
      <xsl:call-template name="css:content"/>
    </abstract>
  </xsl:template>
  
  <!-- BLOCK -->
 
  <xsl:template match="dbk:title" mode="default">
    <title>
      <xsl:call-template name="css:content"/>
    </title>
  </xsl:template>

  <!-- Don’t wrap title content in a bold element -->
  <xsl:template match="@css:font-weight[matches(., '^bold|[6-9]00$')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:if test="$context/ancestor-or-self::*/local-name() = ('figure', 'table')
                  (: figure and table titles are not bold by default; keep the mapping to the bold element here,
                     https://redmine.le-tex.de/issues/8439 :)
                  or
                  not(
                    $context/local-name() = ('title', 'subtitle', 'alt-title')
                    or
                    ($context/local-name() = ('phrase') and $context/ancestor::*/local-name() = ('title', 'subtitle', 'alt-title')) 
                  )">
      <!-- ancestor::* instead of .. in previous expression because of 101024_85813_PFB:
        <title role="hog_paragraphs_headings_sec_p_h_sec1"
                   srcpath="Stories/Story_u5b8.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[17]">
               <phrase role="hub:identifier">
                  <phrase role="ch_text_bold_-_akkurat_ziffer_sec1">
                     <anchor xml:id="page_22"/>1.1</phrase>
               </phrase>
               <tab>	</tab>Grundlage der Loyalität</title> -->
      <xsl:sequence select="$css:bold-elt-name"/>  
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@css:text-decoration-line[. = ('underline')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:sequence select="$css:underline-elt-name"/>
  </xsl:template>
  
  <xsl:template match="@css:text-decoration-line[. = ('line-through')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:sequence select="$css:line-through-elt-name"/>
  </xsl:template>
  
  <xsl:template match="dbk:title[dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')]]" mode="default">
    <xsl:variable name="identifier" select="dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1]" as="element(dbk:phrase)?"/>
    <xsl:if test="normalize-space($identifier) or dbk:anchor[matches(@xml:id, '^(cell)?page_')][. &lt;&lt; $identifier]">
      <label>
        <xsl:apply-templates select="dbk:anchor[matches(@xml:id, '^(cell)?page_')][. &lt;&lt; $identifier]" mode="#current"/>
        <xsl:apply-templates mode="#current" select="$identifier/node()"/>
      </label>
    </xsl:if>
    <title>
      <xsl:apply-templates mode="#current"
        select="@*, node() except ($identifier | dbk:tab | dbk:anchor[matches(@xml:id, '^(cell)?page_')][. &lt;&lt; $identifier])"/>
    </title>
  </xsl:template>
  
  <xsl:template match="dbk:para | dbk:simpara" mode="default">
    <p><xsl:call-template name="css:content"/></p>
  </xsl:template>
  
  <xsl:template match="dbk:blockquote" mode="default">
    <disp-quote><xsl:call-template name="css:content"/></disp-quote>
  </xsl:template>
  
  <xsl:template match="dbk:attribution" mode="default">
    <attrib><xsl:call-template name="css:content"/></attrib>
  </xsl:template>
  
  <xsl:template match="dbk:blockquote" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="* except (attrib|permissions), attrib, permissions" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- INLINE -->
  
  <xsl:variable name="css:italic-elt-name" as="xs:string" select="'italic'"/>
  <xsl:variable name="css:bold-elt-name" as="xs:string" select="'bold'"/>
  <xsl:variable name="css:underline-elt-name" as="xs:string?" select="'underline'"/>
  <xsl:variable name="css:line-through-elt-name" as="xs:string?" select="'strike'"/>
  <xsl:variable name="css:small-caps-name" as="xs:string?" select="'sc'"/>
  
  <xsl:template match="@css:font-variant[matches(., '^small-caps')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:sequence select="$css:small-caps-name"/>
  </xsl:template>
  
  <!-- roles with css-atts that should not be mapped to elements -->
  <xsl:variable name="literal-phrase-style-role-regex" select="'letex_Blockade'"/>
  
  <xsl:template match="dbk:phrase[not(matches(@role, $literal-phrase-style-role-regex))]" mode="default">
    <styled-content><xsl:call-template name="css:content"/></styled-content>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[matches(@role, $literal-phrase-style-role-regex)]" mode="default">
    <styled-content><xsl:apply-templates select="@*, node()" mode="#current"/></styled-content>
  </xsl:template>

  <xsl:template match="dbk:phrase/@role" mode="default">
    <xsl:attribute name="style-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:link[@linkend | @linkends]" mode="default">
    <xref><xsl:call-template name="css:content"/></xref>
  </xsl:template>
  
  <xsl:template match="dbk:link[@linkend | @linkends]/@role" mode="default">
    <xsl:attribute name="ref-type" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:link/@remap[not(. = ('HyperlinkTextDestination'))]" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:link[@xlink:href]|dbk:ulink[@url]" mode="default">
    <ext-link><xsl:call-template name="css:content"/></ext-link>
  </xsl:template>
  
  <xsl:template match="dbk:ulink/@url" mode="default">
    <xsl:attribute name="ext-link-type" select="'uri'"/>
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:ulink/@hub:*"/>

  <xsl:template match="dbk:xref[@linkend]" mode="default">
    <xref rid="{@linkend}">
      <xsl:apply-templates select="@* except (@linkend | @endterm), @endterm, node()" mode="#current"/>
    </xref>
  </xsl:template>

  <xsl:template match="@endterm" mode="default">
    <named-content content-type="link-text" rid="{.}"/>
  </xsl:template>

  <xsl:template match="dbk:anchor" mode="default">
    <target>
      <xsl:call-template name="css:content"/>
    </target>
  </xsl:template>
  
  <xsl:template match="dbk:anchor/@role" mode="default">
    <xsl:attribute name="target-type" select="."/>
  </xsl:template>

  <xsl:template match="boxed-text/target | boxed-text/sec/target | boxed-text/sec/sec/target" mode="clean-up">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:br | dbk:phrase[@role = 'br']" mode="default" priority="1">
    <break/>
  </xsl:template>
  
  <xsl:variable name="break-parents" as="xs:string*"
    select="('aff', 'alt-title', 'article-title', 'attrib', 'bold', 'book-title', 'chapter-title', 'chem-struct', 
             'collab', 'compound-kwd-part', 'corresp', 'disp-formula', 'fixed-case', 'institution', 'italic', 'kwd', 
             'label', 'monospace', 'nav-pointer', 'overline', 'part-title', 'product', 'publisher-loc', 
             'related-article', 'related-object', 'roman', 'sans-serif', 'sc', 'serif', 'sig', 'sig-block', 'source', 
             'std-organization', 'strike', 'sub', 'subject', 'subtitle', 'sup', 'target', 'td', 'th', 'title', 
             'trans-source', 'trans-subtitle', 'trans-title', 'underline', 'volume-title', 'xref')"/>
  
  <xsl:template match="break[not(name(..) = $break-parents)]" mode="clean-up">
    <xsl:processing-instruction name="break"/>
  </xsl:template>
  
  <xsl:template match="dbk:superscript" mode="default">
    <sup>
      <xsl:call-template name="css:content"/>
    </sup>
  </xsl:template>
  
  <xsl:template match="dbk:subscript" mode="default">
    <sub>
      <xsl:call-template name="css:content"/>
    </sub>
  </xsl:template>
  
  <xsl:template match="@align" mode="default">
    <xsl:attribute name="css:text-align" select="."/>
  </xsl:template>
  
  <xsl:template match="@width" mode="default">
    <xsl:attribute name="css:width" select="if (matches(., '^[\d.]+$')) then concat(., 'pt') else ."/>
  </xsl:template>
  
  <xsl:variable name="jats:speech-para-regex" as="xs:string" select="'letex_speech'"/>
  <xsl:variable name="jats:speaker-regex" as="xs:string" select="'letex_speaker'"/>
  <xsl:variable name="jats:no-speaker-regex" as="xs:string" select="'letex_no_speaker'"/>
  
  <xsl:template match="dbk:para[matches(@role, $jats:speech-para-regex)]" mode="default" priority="4">
    <speech>
      <xsl:if test="exists(descendant::dbk:phrase[matches(@role,  $jats:speaker-regex)]) or matches(., '^[\S]+?:.*\S+') and not(matches(@role, $jats:no-speaker-regex))">
      <speaker>
        <xsl:choose>
          <xsl:when test="dbk:phrase[matches(@role, $jats:speaker-regex)] or dbk:phrase/dbk:phrase[matches(@role, $jats:speaker-regex)]">
            <xsl:apply-templates select="descendant::dbk:phrase[@role][matches(@role, $jats:speaker-regex)]/@* except descendant::dbk:phrase[matches(@role, $jats:speaker-regex)]/@role" mode="#current"/>
            <xsl:if test="descendant::dbk:phrase[@role][matches(@role, $jats:speaker-regex)]">
              <xsl:attribute name="content-type" select="descendant::dbk:phrase[@role][matches(@role, $jats:speaker-regex)]/@role"/>
            </xsl:if>
            <xsl:apply-templates select="(dbk:phrase[@role][matches(@role, $jats:speaker-regex)], dbk:phrase[dbk:phrase[@role][matches(@role, $jats:speaker-regex)]])[1]/node()" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="replace(., '^([\S]+?:)(.+)$', '$1', 's')"/>
          </xsl:otherwise>
        </xsl:choose>
      </speaker>
      </xsl:if>
      <p>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:choose>
          <xsl:when test="exists(descendant::dbk:phrase[matches(@role,  $jats:speaker-regex)])">
            <xsl:apply-templates select="node() except (dbk:phrase[matches(@role, $jats:speaker-regex)], dbk:phrase[dbk:phrase[matches(@role, $jats:speaker-regex)]], dbk:tab)" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- the speaker has to be eliminated in next mode -->
            <xsl:apply-templates select="node()" mode="#current">
              <xsl:with-param name="discard" as="xs:boolean" tunnel="yes" select="true()"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </p>
    </speech>  
  </xsl:template>
  
  <xsl:template match="dbk:phrase[matches(@role, $jats:speaker-regex)]" mode="default">
    <xsl:param name="discard" tunnel="yes" as="xs:boolean?"/>
    <xsl:if test="not($discard)">
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="speaker/@content-type" mode="clean-up" priority="2"/>
  
  <xsl:template match="text()[(ancestor::*[self::p])[1]/preceding-sibling::*[1][self::speaker[not(@content-type)]]][matches(., '^[\S]+?:', 's')]" mode="clean-up">
    <xsl:if test="(ancestor::*[self::p])[1]/preceding-sibling::*[1][self::speaker[matches(., '^[\S]+?:', 's')]]">
      <xsl:value-of select="replace(., '^([\S]+?:)\p{Zs}*(.+)$', '$2', 's')"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*[speech]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" group-starting-with="speech[speaker]">
        <xsl:variable name="context" select="current-group()"/>
        <xsl:choose>
          <xsl:when test="current-group()[self::speech]">
            <xsl:for-each-group select="current-group()" group-ending-with="*[jats:is-speech-end(.)]">
              <xsl:choose>
                <xsl:when test="current-group()[self::speech][speaker]">
                  <speech>
                    <xsl:apply-templates select="current-group()/node()" mode="#current"/>
                  </speech>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:for-each select="current-group()">
                    <xsl:apply-templates select="." mode="#current"/>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
   
   <xsl:template match="speech[*[1][not(self::speaker)]][preceding-sibling::*[1][not(self::speech)]]" mode="clean-up" priority="5">
     <xsl:apply-templates mode="#current"/>
   </xsl:template>
  
    <xsl:function name="jats:is-speech-end" as="xs:boolean">
      <xsl:param name="context" as="element(*)*"/>
      <xsl:choose>
        <xsl:when test="$context[not(self::speech)]">
          <xsl:sequence select="true()"/>
        </xsl:when>
        <xsl:when test="$context[self::speech][following-sibling::*[1][not(self::speech)]]">
          <xsl:sequence select="true()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
  
  
  <!-- INDEXTERMS -->
  
  <xsl:template match="dbk:indexterm" mode="default">
    <index-term>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="dbk:primary" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:indexdiv" mode="default">
    <index-div>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </index-div>
  </xsl:template>
  
<!--  static index-->
  
  <xsl:template match="dbk:indexdiv/dbk:title" mode="default">
    <index-title-group>
      <title>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </title>
    </index-title-group>
  </xsl:template>
  
  <xsl:template match="dbk:indexentry" mode="default">
    <index-entry>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </index-entry>
  </xsl:template>
  
  <xsl:function name="tr:create-static-index">
    <xsl:param name="index-entry"/>
      <index-entry>
      <xsl:for-each-group select="$index-entry/node()" group-starting-with="dbk:xref[1]">
        <xsl:choose>
          <xsl:when test="current-group()[self::dbk:xref]">
            <nav-pointer-group>
              <xsl:apply-templates select="current-group()" mode="default"/>
            </nav-pointer-group>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each-group select="current-group()" group-adjacent="self::dbk:seealsoie or self::dbk:seeie">
              <xsl:choose>
                <xsl:when test="not(current-grouping-key())">
                  <term>
                    <xsl:apply-templates select="current-group()" mode="default"/>
                  </term>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="current-group()" mode="default"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
      </index-entry>
  </xsl:function>
  
  <xsl:template match="*[local-name()=('primaryie','secondaryie','tertiaryie')]/dbk:tab" mode="default"/>
  
  <xsl:template match="dbk:primaryie" mode="default">
    <xsl:sequence select="tr:create-static-index(.)/*"/>
  </xsl:template>
  
  <xsl:template match="dbk:xref[ancestor::dbk:indexentry]" mode="default">
    <nav-pointer nav-pointer-type="{(@annotations, 'point')[1]}">
      <xsl:attribute name="rid" select="@xlink:href"/>
      <xsl:value-of select="replace(@xlink:href,'page-','')"/>
    </nav-pointer>
  </xsl:template>
  
  <xsl:template match="dbk:secondaryie" mode="default">
    <index-entry>
     <xsl:sequence select="tr:create-static-index(.)/*"/>
      <xsl:variable name="context" select="." />
      <xsl:apply-templates select="following-sibling::dbk:tertiaryie[preceding-sibling::dbk:secondaryie[1] = $context]" mode="#current">
        <xsl:with-param name="process" select="true()"/>
      </xsl:apply-templates>
    </index-entry>
  </xsl:template>
  
  <xsl:template match="dbk:tertiaryie" mode="default">
    <xsl:param name="process"/>
    <xsl:if test="$process">
      <index-entry>
       <xsl:sequence select="tr:create-static-index(.)/*"/>
      </index-entry>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="dbk:seeie" mode="default">
    <see-entry>
      <xsl:apply-templates mode="#current"/>
    </see-entry>
  </xsl:template>
  
  <xsl:template match="dbk:seealsoie" mode="default">
    <see-also-entry>
      <xsl:apply-templates mode="#current"/>
    </see-also-entry>
  </xsl:template>
  
  <!-- not supported in JATS -->
  <xsl:template match="dbk:indexterm/@pagenum" mode="default"/>
    
  <xsl:template match="dbk:primary" mode="default">
    <xsl:apply-templates select="@sortas" mode="#current"/>
    <term>
      <xsl:apply-templates select="@css:*, node() except (dbk:see, dbk:seealso)" mode="#current"/>
    </term>
    <xsl:apply-templates select="if(../dbk:secondary) then ../dbk:secondary 
                                 else ( ../dbk:see union ../dbk:seealso union dbk:see union dbk:seealso)" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:secondary" mode="default">
    <index-term>
      <xsl:apply-templates select="@sortas" mode="#current"/>
      <term>
        <xsl:apply-templates select="@css:*, node()" mode="#current"/>
      </term>
      <xsl:apply-templates select="if(../dbk:tertiary) then ../dbk:tertiary else ( ../dbk:see | ../dbk:seealso)" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:tertiary" mode="default">
    <index-term>
      <xsl:apply-templates select="@sortas" mode="#current"/>
      <term>
        <xsl:apply-templates select="@css:*, node()" mode="#current"/>
      </term>
      <xsl:apply-templates select="if(../dbk:quaternary) then ../dbk:quaternary else (../dbk:see | ../dbk:seealso)" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:quaternary" mode="default">
    <index-term>
      <xsl:apply-templates select="@sortas" mode="#current"/>
      <term>
        <xsl:apply-templates select="@css:*, node()" mode="#current"/>
      </term>
      <xsl:apply-templates select="if(../dbk:quinary) then ../dbk:quinary else (../dbk:see | ../dbk:seealso)" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:quinary" mode="default">
    <index-term>
      <xsl:apply-templates select="@sortas" mode="#current"/>
      <term>
        <xsl:apply-templates select="@css:*, node()" mode="#current"/>
      </term>
      <xsl:apply-templates select="../dbk:see | ../dbk:seealso" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:see" mode="default">
    <see>
      <xsl:call-template name="css:content"/>
    </see>
  </xsl:template>
  
  <xsl:template match="dbk:seealso" mode="default">
    <see-also>
      <xsl:call-template name="css:content"/>
    </see-also>
  </xsl:template>

  <xsl:template match="@sortas" mode="default">
    <xsl:attribute name="sort-key" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:indexterm/@class[. = ('startofrange', 'endofrange', 'singular')]" mode="default"/>
  
  <xsl:template match="dbk:indexterm/@startref" mode="default">
    <xsl:attribute name="rid" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:indexterm/@type | dbk:index/@type" mode="default">
    <xsl:attribute name="index-type" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:indexterm[@class = 'endofrange']" mode="default">
    <index-term-range-end>
      <xsl:call-template name="css:content"/>
    </index-term-range-end>
  </xsl:template>
  
  <xsl:template match="term" mode="clean-up">
    <xsl:copy>
      <xsl:call-template name="css:content"/>
    </xsl:copy>
  </xsl:template>

  <!-- FOOTNOTES -->
  
  <xsl:template match="dbk:footnote" mode="default">
    <xsl:param name="create-xref-for-footnotes" as="xs:boolean?" select="false()" tunnel="yes"/>
    <xsl:variable name="label" select="dbk:para[1]/*[1][self::dbk:phrase][@role eq 'hub:identifier']" as="element(dbk:phrase)?"/>
    <xsl:choose>
      <xsl:when test="$create-xref-for-footnotes">
        <xref ref-type="fn">
          <xsl:attribute name="rid">
            <xsl:apply-templates select="@xml:id" mode="#current"/>
          </xsl:attribute>
          <xsl:apply-templates select="@xml:id" mode="optionally-create-id"/>
          <sup><xsl:value-of select="$label"/></sup>
        </xref>
      </xsl:when>
      <xsl:otherwise>
        <fn>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:if test="$label">
            <label>
              <xsl:apply-templates select="$label" mode="fn-label"/>
            </label>  
          </xsl:if>
          <xsl:apply-templates mode="#current"/>
        </fn>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:footnote/@xml:id" mode="optionally-create-id">
    <!-- this can be overwritten to add @id -->
  </xsl:template>
  
  <xsl:template match="dbk:footnote/@label | dbk:footnoteref/@label" mode="default">
    <xsl:attribute name="symbol" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:footnote/dbk:para[1]/node()[1][self::dbk:phrase][@role eq 'hub:identifier']" mode="fn-label">
    <xsl:apply-templates mode="default"/>
  </xsl:template>
  
  <xsl:template match="dbk:footnote/dbk:para[1]/node()[1][self::dbk:phrase][@role eq 'hub:identifier']" mode="default" priority="2"/>
  
  <!-- LISTS -->
  
  <xsl:template match="dbk:orderedlist" mode="default">
    <list list-type="order">
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="dbk:itemizedlist" mode="default">
    <list list-type="bullet">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="dbk:variablelist" mode="default">
    <def-list>
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def-list>
  </xsl:template>
  
  <xsl:template match="dbk:variablelist/@role" mode="default">
    <xsl:attribute name="list-type" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:varlistentry" mode="default">
    <def-item>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def-item>
  </xsl:template>

  <xsl:template match="dbk:varlistentry/dbk:term" mode="default">
    <term>
      <xsl:call-template name="css:content"/>
    </term>
  </xsl:template>
  
	<xsl:template match="dbk:variablelist[ancestor::*[self::dbk:variablelist]] | 
	                     dbk:itemizedlist[ancestor::*[self::dbk:variablelist]] | 
	                     dbk:orderedlist[ancestor::*[self::dbk:variablelist]]" mode="default" priority="5">
    <!-- in BITS, the def element may only hold p elements, therefore we need to wrap nested lists: -->
    <p specific-use="{name()}">
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:varlistentry/dbk:listitem" mode="default">
    <def>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def>
  </xsl:template>
  
  <xsl:template match="@numeration" mode="default">
    <xsl:choose>
      <xsl:when test=". = 'arabic'"><xsl:attribute name="list-type" select="'order'"/></xsl:when>
      <xsl:when test=". = 'upperalpha'"><xsl:attribute name="list-type" select="'alpha-upper'"/></xsl:when> 
      <xsl:when test=". = 'loweralpha'"><xsl:attribute name="list-type" select="'alpha-lower'"/></xsl:when>
      <xsl:when test=". = 'upperroman'"><xsl:attribute name="list-type" select="'roman-upper'"/></xsl:when> 
      <xsl:when test=". = 'lowerroman'"><xsl:attribute name="list-type" select="'roman-lower'"/></xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@continuation[. = 'continues']" mode="default">
    <xsl:variable name="preceding-list" select="../preceding-sibling::dbk:orderedlist[1]" as="element(dbk:orderedlist)?"/>
    <xsl:attribute name="continued-from" select="$preceding-list/(@xml:id, generate-id())[1]"/>    
    <xsl:if test="not($preceding-list)">
      <xsl:message>hub2bits: No list to continue found. Look for an empty continued-from attribute in the output.</xsl:message>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="@startingnumber" mode="default">
    <xsl:message>hub2bits: No startingnumber support in BITS. Attribute copied nonetheless.</xsl:message>
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="dbk:listitem" mode="default">
    <list-item>
      <xsl:apply-templates select="@* except @override, @override, node()[not(self::dbk:anchor and . is ../node()[1])]" mode="#current"/>
    </list-item>
  </xsl:template>
  
  <xsl:template match="dbk:listitem/@override" mode="default">
    <label>
      <xsl:if test="../node()[1][self::dbk:anchor]"><xsl:apply-templates select="../node()[1]" mode="#current"/></xsl:if>
      <xsl:value-of select="."/>
    </label>
  </xsl:template>
  
  <xsl:template match="dbk:listitem/dbk:figure" mode="default">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:itemizedlist/@mark" mode="default">
    <xsl:variable name="type" as="xs:string?">
      <xsl:choose>
        <xsl:when test=". = ('&#x25fd;', '&#x25fb;')"><xsl:sequence select="concat('''', ., '''')"/></xsl:when>
        <xsl:when test=". = '&#x2713;'"><xsl:sequence select="'check'"/></xsl:when>
        <xsl:when test=". = ('&#x25e6;', '&#x25cb;')"><xsl:sequence select="'circle'"/></xsl:when>
        <xsl:when test=". = '&#x25c6;'"><xsl:sequence select="'diamond'"/></xsl:when>
        <xsl:when test=". = '&#x2022;'"><xsl:sequence select="'disc'"/></xsl:when>
        <xsl:when test=". = ('&#x2013;', '&#x2014;')"><xsl:sequence select="'hyphen'"/></xsl:when>
        <xsl:when test=". = ('&#x25fe;', '&#x25fc;')"><xsl:sequence select="'square'"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$type">
      <xsl:attribute name="css:list-style-type" select="$type"/>  
    </xsl:if>
  </xsl:template>
  
  <!-- BOXES -->
  
  <xsl:function name="jats:box-type" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:apply-templates select="$elt" mode="box-type"/>
  </xsl:function>

  <!-- override these templates in your customization so that there remains a single text node
       that gives the box type -->
  
  <xsl:template match="*" mode="box-type">
    <xsl:apply-templates select="@*, *" mode="#current"/>
  </xsl:template>

  <xsl:template match="@*" mode="box-type"/>
  
  <xsl:template match="dbk:sidebar[@remap eq 'Group']" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:sidebar | dbk:formalpara | dbk:div" mode="default">
    <boxed-text>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </boxed-text>
  </xsl:template>
  
  <xsl:template match="dbk:sidebar[dbk:title]" mode="default">
    <boxed-text>
      <xsl:apply-templates select="@*" mode="#current"/>
      <sec>
        <xsl:apply-templates mode="#current"/>
      </sec>
    </boxed-text>
  </xsl:template>
  
  <!-- POETRY -->
  
  <xsl:template match="dbk:poetry | dbk:poetry/dbk:linegroup | dbk:linegroup[not(parent::dbk:poetry)] " mode="default">
    <verse-group>
      <xsl:apply-templates select="@*, node() except *[matches(@role, $jats:verse-group-attrib) or self::dbk:legalnotice or self::dbk:copyright], 
                                   *[matches(@role, $jats:verse-group-attrib) or self::dbk:legalnotice or self::dbk:copyright]" mode="#current"/>
    </verse-group>
  </xsl:template>
  
  <xsl:variable name="jats:verse-group-attrib" as="xs:string" select="'tr-verse-line-attrib'"/>

  <xsl:template match="dbk:poetry/dbk:linegroup[matches(@role, $jats:verse-group-attrib)]" mode="default" priority="3">
    <attrib>
      <xsl:apply-templates select="@* except @role, dbk:line/node()" mode="#current"/>
    </attrib>
  </xsl:template>

  <xsl:template match="dbk:linegroup/dbk:line" mode="default">
    <verse-line>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-line>
  </xsl:template>
  
  
  <!-- FIGURES -->
  
  <xsl:template match="dbk:figure" mode="default">
    <xsl:element name="{if (dbk:informalfigure) then 'fig-group' else 'fig'}">
      <xsl:call-template name="css:other-atts"/>
      <xsl:apply-templates select="(@xml:id, (.//dbk:anchor[not(matches(@xml:id, '^(cell)?page_'))])[1]/@xml:id)[1]" mode="#current"/>
      <label>
        <xsl:apply-templates select=".//*:anchor[matches(@xml:id, '^(cell)?page_')][1]" mode="#current"/>
        <xsl:apply-templates mode="#current" select="dbk:title/dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1]"/>
      </label>
      <caption>
        <title>
          <xsl:apply-templates mode="#current"
                               select="dbk:title/@*,
                                       dbk:title/(node() except (dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1] 
                                                               |dbk:tab
                                                               |*:anchor[matches(@xml:id, '^(cell)?page_')][1]))"/>
        </title>
         <xsl:if test="dbk:caption">
          <xsl:apply-templates select="dbk:caption/dbk:para" mode="#current"/>
        </xsl:if>
        <xsl:if test="dbk:note">
          <xsl:apply-templates select="dbk:note/dbk:para" mode="#current"/>
        </xsl:if>
      </caption>
      <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']] | dbk:note | dbk:caption)" mode="#current"/>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dbk:informalfigure" mode="default">
    <fig>
      <xsl:call-template name="css:other-atts"/>
      <xsl:apply-templates select="(@xml:id, (.//dbk:anchor[not(matches(@xml:id, '^(cell)?page_'))])[1]/@xml:id)[1]" mode="#current"/>
      
      <xsl:if test="dbk:caption[normalize-space()] or dbk:note[normalize-space()]">
        <caption>
          <xsl:if test="dbk:caption">
            <xsl:apply-templates select="dbk:caption/dbk:para" mode="#current"/>
          </xsl:if>
          <xsl:if test="dbk:note">
            <xsl:apply-templates select="dbk:note/dbk:para" mode="#current"/>
          </xsl:if>
        </caption>
      </xsl:if>
      <xsl:apply-templates select="* except (dbk:info[dbk:legalnotice[@role eq 'copyright']] | dbk:note | dbk:caption)" mode="#current"/>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </fig>
  </xsl:template>
  
  <xsl:template match="dbk:figure/@role" mode="default">
    <xsl:attribute name="fig-type" select="."/>
  </xsl:template>
  
  <xsl:template match="fig[target]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id" select="target/@id"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current">
          <xsl:with-param name="move-floating-target-in-fig-to-caption" select="if (@id) then true() else false()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="fig/target" mode="clean-up"/>
  
  <xsl:template match="fig/label" mode="clean-up">
    <xsl:param name="move-floating-target-in-fig-to-caption" as="xs:boolean?" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$move-floating-target-in-fig-to-caption">
        <xsl:copy-of select="../target"/>
      </xsl:if>
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="dbk:figure/dbk:note" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:info/dbk:legalnotice[@role eq 'copyright']" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:info/dbk:legalnotice[@role eq 'license']" mode="default">
    <license>
      <xsl:apply-templates mode="#current"/>
    </license>
  </xsl:template>
  
  <xsl:template match="dbk:info/dbk:legalnotice[@role eq 'license']/dbk:para" mode="default">
    <license-p>
      <xsl:apply-templates mode="#current"/>
    </license-p>
  </xsl:template>
  
  <xsl:template match="dbk:info/dbk:legalnotice[@role eq 'copyright']/dbk:para" mode="default">
    <copyright-statement>
      <xsl:apply-templates select="@* except @role, node()" mode="#current"/>
    </copyright-statement>
  </xsl:template>
  
  <xsl:template match="dbk:mediaobject | dbk:inlinemediaobject | dbk:imageobject" mode="default">
    <xsl:if test="@xml:id">
      <target id="{@xml:id}"/>
    </xsl:if>
    <xsl:apply-templates select="node() except dbk:alt" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:imagedata" mode="default">
    <xsl:element name="{if ( 
                             not(matches(name(../../..), '^(figure|informalfigure|entry|colophon|table|alt|sidebar|sect(\d|ion))$'))
                             or
                             name(../..) = 'inlinemediaobject' 
                             )
                        then 'inline-graphic' 
                        else 'graphic'}">
      <xsl:apply-templates select="(ancestor::dbk:mediaobject | ancestor::dbk:inlinemediaobject)[1]/(@xml:id|@role)" mode="#current"/>
      <xsl:call-template name="css:content"/>
      <xsl:apply-templates select="(ancestor::dbk:mediaobject | ancestor::dbk:inlinemediaobject)[1]/dbk:alt" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:alt" mode="default">
    <alt-text><xsl:apply-templates mode="#current"/></alt-text>
  </xsl:template>

  <!-- Override in adaptions -->
  <xsl:template match="dbk:imagedata/@fileref" mode="default">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <!-- TABLES -->
  
  <!-- todo: group with table footnotes -->
    
  <xsl:template match="dbk:row" mode="default">
    <tr>
      <xsl:call-template name="css:content"/>
    </tr>
  </xsl:template>
  
  <xsl:template match="dbk:tgroup" mode="default">
    <xsl:choose>
      <xsl:when test="dbk:colspec">
        <colgroup>
          <xsl:apply-templates select="dbk:colspec" mode="#current"/>
        </colgroup>
        <xsl:apply-templates select="node() except dbk:colspec" mode="#current">
          <xsl:sort select="index-of(('colspec', 'thead', 'tfoot', 'tbody', 'row'), local-name())"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="css:content"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:tgroup/@cols" mode="default"/>
  
  <xsl:template match="dbk:tbody" mode="default">
    <tbody>
      <xsl:call-template name="css:content"/>
    </tbody>
  </xsl:template>

  <xsl:template match="dbk:tfoot" mode="default">
    <tfoot>
      <xsl:call-template name="css:content"/>
    </tfoot>
  </xsl:template>

  <xsl:template match="dbk:colspec[@colwidth]" mode="default">
    <col>
      <xsl:apply-templates select="@colwidth" mode="#current"/>
    </col>
  </xsl:template>
  
  <xsl:template match="dbk:colspec/@colwidth" mode="default">
    <xsl:attribute name="width" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:table/@css:width | dbk:informaltable/@css:width" mode="default" priority="2">
    <xsl:attribute name="{local-name()}" select="."/>
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="dbk:thead" mode="default">
    <thead>
      <xsl:call-template name="css:content"/>
    </thead>
  </xsl:template>
  
  <xsl:template match="dbk:entry" mode="default">
    <xsl:element name="{if (ancestor::dbk:thead) then 'th' else 'td'}">
      <xsl:call-template name="css:content"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@namest" mode="default">
    <xsl:attribute name="colspan" select="number(replace(../@nameend, 'c(ol)?', '')) - number(replace(., 'c(ol)?', '')) + 1"/>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@morerows" mode="default">
    <xsl:if test="xs:integer(.) ge 1">
      <xsl:attribute name="rowspan" select=". + 1"/>
    </xsl:if>
  </xsl:template>
  
   <xsl:template match="dbk:table/dbk:title" name="dbk:table-title" mode="default" priority="2">
     <xsl:if test="dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1]">
       <label>
         <xsl:apply-templates select="dbk:anchor[matches(@xml:id, '^(cell)?page_')][1]" mode="#current"/>
         <xsl:apply-templates mode="#current" select="dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1]"/>
       </label>
       </xsl:if>
     <xsl:if test=".//text() or ../dbk:caption">
       <caption>
         <xsl:if test=".//text()">
         <title>
           <xsl:apply-templates mode="#current"
             select="@* | node() except (dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1] | dbk:tab | dbk:anchor[matches(@xml:id, '^(cell)?page_')][1])"/>
         </title>
         </xsl:if>
       <xsl:if test="../dbk:caption">
           <xsl:apply-templates select="../dbk:caption/dbk:note/dbk:para, ../dbk:caption/dbk:para" mode="#current"/>
         </xsl:if>
       </caption>
       </xsl:if>
   </xsl:template>
  
  <xsl:template match="dbk:textobject | dbk:caption | dbk:note" mode="default"/>
  
  <xsl:template match="dbk:caption//dbk:para | dbk:textobject/dbk:para" mode="default">
    <p>
      <xsl:call-template name="css:content"/>
    </p>
  </xsl:template>  
  
  <xsl:template name="more-specific-box-content-type">
    <!-- customization hook for creating specific-use="TOC_sub" -->
  </xsl:template>
  
  <xsl:template match="dbk:informaltable | dbk:table" mode="default">
    <xsl:if test="dbk:textobject[every $elt in node() satisfies $elt/self::dbk:sidebar]">
      <xsl:apply-templates select="dbk:textobject/node()" mode="#current"/>
    </xsl:if>
    <table-wrap>
      <xsl:variable name="context" select="."/>
      <xsl:call-template name="more-specific-box-content-type"/>
      <xsl:apply-templates select="@* except (@role | @css:*| @width), dbk:title | dbk:caption[exists(current()//dbk:tr)]" mode="#current"/>
      <xsl:choose>
        <xsl:when test="exists(dbk:mediaobject) and not(dbk:tgroup)">
          <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']])" mode="#current"/>
          <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
        </xsl:when>
        <xsl:when test="exists(dbk:tgroup/*/dbk:row)">
          <!-- if there is an alternative image (additional to the real table) -->
          <xsl:apply-templates select="dbk:alt" mode="#current"/>
          <xsl:for-each select="dbk:tgroup">
            <table>
              <xsl:apply-templates select="../@role | ../@css:* | ../@width" mode="#current"/>
              <xsl:if test="@tgroupstyle">
                <!-- when this att exists, several tables were merged into one table in hub. regain their atts-->
                <xsl:apply-templates select="@tgroupstyle | @css:* | @width" mode="#current"/>
              </xsl:if>
              <xsl:apply-templates select="." mode="#current"/>
              <!--<xsl:apply-templates select="* except (dbk:alt | dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']])" mode="#current"/>-->
            </table>
              <xsl:apply-templates select="$context/dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <table>
            <xsl:apply-templates select="@role | @css:*" mode="#current"/>
<!--            <HTMLTABLE_TODO/>-->
            <xsl:apply-templates select="node() except dbk:caption[exists(current()//dbk:tr)]" mode="#current"/>
          </table>
        </xsl:otherwise>
      </xsl:choose>
      <!--<xsl:for-each select="self::dbk:informaltable">
        <xsl:call-template name="css:other-atts"/>
        </xsl:for-each>-->
      <!-- extra content-type attribute at the contained table (also process css here, only id above?): -->
      <xsl:if test="dbk:textobject[not(every $elt in node() satisfies $elt/self::dbk:sidebar)]">
        <table-wrap-foot>
          <xsl:apply-templates select="dbk:textobject/dbk:para" mode="#current"/>
        </table-wrap-foot>
      </xsl:if>
    </table-wrap>
  </xsl:template>
  
  <!-- HTML TABLES -->
  <xsl:template match="dbk:tr | dbk:td | dbk:th | dbk:colgroup | dbk:col" mode="default">
    <xsl:element name="{local-name()}">
      <xsl:call-template name="css:content"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:tr | dbk:td | dbk:th | dbk:colgroup | dbk:col" mode="class-att">
    <xsl:if test="exists(@class)">
      <xsl:attribute name="content-type" select="@class"/>  
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="dbk:caption[..//dbk:tr][count(dbk:para) = 1][count(*) = 1]" mode="default">
    <caption>
      <title>
        <xsl:apply-templates select="dbk:para/node()" mode="#current"/>
      </title>
    </caption>
  </xsl:template>
  
  <xsl:template match="@colspan | @rospan" mode="default">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="@class[parent::dbk:tr | parent::dbk:td | parent::dbk:th | parent::dbk:colgroup | parent::dbk:col]" 
    mode="default"/>
  
  <!-- end HTML TABLES -->
  
  <xsl:template match="dbk:informaltable/dbk:alt | dbk:table/dbk:alt" mode="default">
    <alternatives>
      <xsl:for-each select="dbk:inlinemediaobject/dbk:imageobject/dbk:imagedata/@fileref">
        <graphic xlink:href="{.}"/>
      </xsl:for-each>
    </alternatives>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable" mode="default_DISABLED">
    <array>
      <xsl:call-template name="css:content"/>
    </array>  
  </xsl:template>
  
  <xsl:template match="dbk:colspec | @colname | @nameend" mode="default"/>
  
  
  <!-- EPUB conditional content -->
  
  <xsl:template match="@condition" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <!-- BIBLIOGRAPHY -->
  
  <xsl:template match="dbk:bibliography | dbk:bibliodiv | dbk:bibliolist" mode="default">
    <ref-list>
      <xsl:call-template name="css:content"/>
    </ref-list>
  </xsl:template>

  <xsl:template match="dbk:biblioentry/@annotations" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>

  <xsl:template match="*[local-name() = ('bibliodiv', 'bibliography', 'bibliolist')]
                        /dbk:biblioentry" mode="default">
    <ref>
      <xsl:if test="@xml:id">
        <xsl:attribute name="id" select="@xml:id"/>
      </xsl:if>
      <xsl:call-template name="css:content"/>
    </ref>
  </xsl:template>

  <xsl:template match="*[local-name() = ('bibliodiv', 'bibliography', 'bibliolist')]
                        /dbk:biblioentry[dbk:abstract[@role = 'rendered']]" mode="default" priority="2">
    <ref>
      <xsl:if test="@xml:id">
        <xsl:attribute name="id" select="@xml:id"/>
      </xsl:if>
      <citation-alternatives>
        <xsl:apply-templates select="dbk:abstract[@role = 'rendered'], dbk:biblioset" mode="#current">
          <xsl:with-param name="render" select="true()"/>
        </xsl:apply-templates>
      </citation-alternatives>
    </ref>
  </xsl:template>
  
  <xsl:template match="*[local-name() = ('bibliodiv', 'bibliography', 'bibliolist')]
                        /dbk:biblioentry[dbk:abstract[@role = 'rendered']]/@xml:id" mode="default" priority="3"/>

  <xsl:template match="*[local-name() = ('bibliodiv', 'bibliography', 'bibliolist')]
                        /dbk:biblioentry/@xml:id" mode="default" priority="2">
    <xsl:attribute name="id" select="."/>
  </xsl:template>

  <xsl:template match="dbk:biblioentry/dbk:abstract[@role = 'rendered']" mode="default">
    <xsl:param name="render" select="false()" as="xs:boolean"/>
    <xsl:if test="$render">
      <xsl:for-each select="dbk:para">
        <mixed-citation specific-use="rendered">
          <xsl:call-template name="css:content"/>
        </mixed-citation>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[local-name() = ('bibliodiv', 'bibliography', 'bibliolist')]
                        /dbk:bibliomixed" mode="default">
    <ref>
      <xsl:apply-templates select="@xml:id" mode="#current">
        <xsl:with-param name="render" select="true()" as="xs:boolean"/>
      </xsl:apply-templates>
      <mixed-citation>
        <xsl:call-template name="css:content"/>
      </mixed-citation>
    </ref>
  </xsl:template>
  
  <xsl:template match="*[local-name() = ('bibliodiv', 'bibliography', 'bibliolist')]/dbk:bibliomixed/@xml:id" 
                mode="default">
    <xsl:param name="render" as="xs:boolean" select="false()"/>
    <xsl:if test="$render">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="dbk:biblioset[not(preceding-sibling::dbk:biblioset)]" mode="default">
    <element-citation>
      <xsl:variable name="pubtype" select="../dbk:biblioset/@relation"/>
      <xsl:if test="$pubtype">
        <xsl:attribute name="publication-type" 
          select="($pubtype[. = 'journal'], $pubtype[not(. = 'journal')])[1]"/>
      </xsl:if>
      <xsl:call-template name="css:content"/>
      <xsl:apply-templates select="following-sibling::dbk:biblioset/node()" mode="#current"/>
    </element-citation>
  </xsl:template>
  
  <xsl:template match="dbk:biblioset[preceding-sibling::dbk:biblioset]" mode="default"/>
  <xsl:template match="dbk:biblioset/@relation" mode="default"/>

  <xsl:template match="dbk:biblioset[@relation]/dbk:title" mode="default">
    <xsl:variable name="element-name" as="xs:string">
      <xsl:choose>
        <xsl:when test="parent::*/@relation = 'article'">
          <xsl:value-of select="'article-title'"/>
        </xsl:when>
        <xsl:when test="parent::*/@relation = 'chapter'">
          <xsl:value-of select="'chapter-title'"/>
        </xsl:when>
        <xsl:when test="parent::*/@relation = 'data'">
          <xsl:value-of select="'data-title'"/>
        </xsl:when>
        <xsl:when test="parent::*/@relation = 'issue'">
          <xsl:value-of select="'issue-title'"/>
        </xsl:when>
        <xsl:when test="parent::*/@relation = 'part'">
          <xsl:value-of select="'part-title'"/>
        </xsl:when>
        <xsl:when test="parent::*/@relation = 'trans'">
          <xsl:value-of select="'trans-title'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'_unspecific_'"/><!-- handle me -->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$element-name = '_unspecific_'">
        <source content-type="title" specific-use="{parent::*/@relation}">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </source>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$element-name}">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dbk:biblioset/dbk:titleabbrev" mode="default">
    <abbrev>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </abbrev>
  </xsl:template>

  <xsl:template match="dbk:biblioset[not(@relation)]/dbk:title" mode="default">
    <source content-type="title">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </source>
  </xsl:template>

  <xsl:template match="dbk:biblioset/dbk:abstract" mode="default">
    <annotation content-type="abstract">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </annotation>
  </xsl:template>

  <xsl:template match="dbk:bibliomisc[@role = 'container-title'][ancestor::dbk:*[local-name() = ('biblioentry', 'bibliomixed')]]" mode="default">
    <source content-type="title" specific-use="{@role}">
      <xsl:apply-templates select="@* except @role, node()" mode="#current"/>
    </source>
  </xsl:template>

  <xsl:template match="dbk:bibliomisc[matches(@role, '^ur(i|l)$', 'i')]" mode="default">
    <uri>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </uri>
  </xsl:template>
  <xsl:template match="dbk:bibliomisc/@role[matches(., '^ur(i|l)$', 'i')]" mode="default"/>
  
  <xsl:template match="dbk:bibliomisc[ancestor::dbk:*[local-name() = ('biblioentry', 'bibliomixed')]]" mode="default" priority="-0.75">
    <named-content>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </named-content>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc[ancestor::dbk:*[local-name() = ('biblioentry', 'bibliomixed')]]/@role" mode="default" priority="-0.75">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:biblioset/dbk:date" mode="default">
    <date>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </date>
  </xsl:template>

  <xsl:template match="*:language[namespace-uri() = 'http://purl.org/dc/terms/']" mode="default">
    <named-content content-type="language" vocab="uncontrolled" vocab-identifier="http://purl.org/dc/terms/">
      <xsl:apply-templates mode="#current"/>
    </named-content>
  </xsl:template>

  <xsl:template match="dbk:email" mode="default">
    <email>
      <xsl:call-template name="css:content"/>
    </email>
  </xsl:template>

  <xsl:template match="dbk:revhistory" mode="default">
    <pub-history>
      <xsl:apply-templates select="node() except (dbk:info | dbk:title | dbk:titleabbrev)" mode="#current"/>
    </pub-history>
  </xsl:template>

  <xsl:template match="dbk:revhistory/dbk:revision" mode="default">
    <date>
<!-- suggested: accepted, corrected, pub, preprint, retracted, received, rev-recd, rev-request	 -->
      <xsl:attribute name="date-type" select="     if (some $t in (dbk:revremark|@role) satisfies matches($t, 'accepted|angenommen|akzeptiert', 'i')) then 'accepted' 
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'revision (submitted|received)|Revision einge(reicht|gangen)', 'i')) then 'rev-recd'                                       
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'Manuscript (submitted|received)|Manuskript einge(reicht|gangen)', 'i')) then 'received'
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'retracted|zurückgezogen', 'i')) then 'retracted'
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'corrected|korrigiert','i')) then 'corrected' 
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'revision requested|Revision (verlangt|angefordert)', 'i')) then 'rev-request' 
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'published online|Onlineveröffentlichung|online veröffentlicht', 'i')) then 'epub' 
                                              else if (some $t in (dbk:revremark|@role) satisfies matches($t, 'published|publiziert|veröffentlicht', 'i')) then 'pub' else  'unknown'"/>
      <xsl:if test="dbk:date castable as xs:date">
        <xsl:attribute name="iso-8601-date" select="xs:date(dbk:date)"/>
      </xsl:if>
      <xsl:call-template name="structure-date"/>
    </date>
  </xsl:template>

  <xsl:template name="structure-date">
    <xsl:variable name="date-regex" as="xs:string"
      select="'^((\d+)\.)(\p{Zs}?(\d+\.|\p{Lu}\p{Ll}+))\p{Zs}?(\d{4})'"/><!-- default is german. overwrite template if needed-->
    <xsl:analyze-string select="dbk:date" regex="{$date-regex}">
      <xsl:matching-substring>
        <xsl:if test="regex-group(2)">
          <day>
            <xsl:value-of select="regex-group(2)"/>
          </day>
        </xsl:if>
        <xsl:if test="regex-group(4)">
          <month>
            <xsl:value-of select="substring-before(regex-group(4), '.')"/>
          </month>
        </xsl:if>
        <xsl:if test="regex-group(5)">
          <year>
            <xsl:value-of select="regex-group(5)"/>
          </year>
        </xsl:if>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <string-date>
          <xsl:value-of select="."/>
        </string-date>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template match="dbk:note" mode="default" priority="3">
    <notes>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </notes>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:bibliomisc[@role = 'edition']" mode="default">
    <edition>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </edition>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:bibliomisc/@role[. = 'edition']" mode="default"/>
  
  <xsl:template match="dbk:info/dbk:bibliomisc" mode="default">
    <custom-meta>
      <meta-name><xsl:value-of select="@role"/></meta-name>
      <meta-value><xsl:call-template name="css:content"/></meta-value>
    </custom-meta>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc[not(ancestor::dbk:*[local-name() = ('biblioentry', 'bibliomixed')])][not(parent::dbk:info)]" mode="default">
    <mixed-citation>
      <xsl:if test="parent::*[not(self::dbk:bibliography)]/@xml:id">
        <xsl:attribute name="id" select="../@xml:id"/>  
      </xsl:if>
      <xsl:call-template name="css:content"/>
    </mixed-citation>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomixed/@xreflabel" mode="default">
    <xsl:attribute name="id" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc[tokenize(@role, '\s+') = 'comment']" mode="default">
    <comment>
      <xsl:apply-templates mode="#current"/>
    </comment>
  </xsl:template>
  
  <xsl:template match="dbk:bibliography//dbk:abbrev" mode="default">
    <abbrev>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </abbrev>
  </xsl:template>
  <xsl:template match="dbk:bibliography//dbk:abbrev/@role" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>

  <xsl:template match="dbk:bibliosource" mode="default">
    <source>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </source>
  </xsl:template>
  <xsl:template match="dbk:bibliosource/@role" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  <xsl:template match="dbk:bibliosource/@*[name() = ('class', 'otherclass')]" mode="default">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:othercredit[@role = 'collaborator']" mode="default">
    <collab>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </collab>
  </xsl:template>
  <xsl:template match="dbk:othercredit/@role[. = 'collaborator']" mode="default"/>

  <xsl:template match="dbk:othercredit[@role = 'collaborator']//*[self::dbk:personname or self::dbk:surname]" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:issuenum" mode="default">
    <issue>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </issue>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:pagenums" mode="default">
    <page-range>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </page-range>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:volumenum" mode="default">
    <volume>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </volume>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:releaseinfo" mode="default">
    <string-date>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </string-date>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:releaseinfo//*[preceding-sibling::*]" mode="default">
    <xsl:value-of select="'&#x20;'"/>
    <xsl:next-match/>
  </xsl:template>

  <xsl:template match="dbk:bibliography//dbk:releaseinfo/@role" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>

  <xsl:template match="dbk:biblioentry/@xml:id" mode="default"/>
  
  <xsl:template match="mixed-citation/@*[name() = ('css:margin-left', 'css:text-indent', 'content-type')]
                     | def-item/@*[name() = ('css:margin-left', 'css:text-indent', 'content-type')]" mode="clean-up"/>

  <xsl:template match="abstract/table-wrap" mode="clean-up">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>

  <xsl:template match="dbk:confgroup" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:conftitle" mode="default">
    <conf-name>
      <xsl:apply-templates mode="#current"/>
    </conf-name>
  </xsl:template>

  <xsl:template match="dbk:confgroup/dbk:address" mode="default">
    <conf-loc>
      <xsl:apply-templates mode="#current"/>
    </conf-loc>
  </xsl:template>
  
  <xsl:template match="dbk:affiliation/dbk:address" mode="default">
    <addr-line>
      <xsl:apply-templates mode="#current"/>
    </addr-line>
  </xsl:template>
  
  <xsl:template match="dbk:*[local-name() = ('biblioref', 'citation')][not(@endterm) and (@linkend or @linkends)]" mode="default">
    <xref ref-type="bibr" rid="{(@linkends, @linkend)[1]}">
      <xsl:apply-templates mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="dbk:issuenum" mode="default">
    <issue>
      <xsl:call-template name="css:content"/>
    </issue>
  </xsl:template>

  <xsl:template match="sup/@xml:lang | sub/@xml:lang" mode="clean-up"/>
  
  <!-- equations -->
  
  <xsl:template match="dbk:listitem/dbk:equation" mode="default" priority="2">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:equation" mode="default">
    <disp-formula>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </disp-formula>
  </xsl:template>
  
  <xsl:template match="dbk:equation[dbk:alt/@role = 'TeX'][mml:math]" mode="default">
    <disp-formula>
      <xsl:apply-templates select="@* except @label, @label, dbk:info | dbk:title" mode="#current"/>
      <alternatives>
        <xsl:apply-templates select="* except dbk:info | dbk:title" mode="#current"/>
      </alternatives>
    </disp-formula>
  </xsl:template>
  
  <xsl:template match="@label
                      |dbk:equation/dbk:title
                      |dbk:inlineequation/dbk:title" mode="default">
    <label><xsl:value-of select="."/></label>
  </xsl:template>
  
  <xsl:template match="dbk:alt[@role = 'TeX'] | dbk:mathphrase[@role = 'TeX']" mode="default">
    <tex-math>
      <xsl:value-of select="."/>
    </tex-math>
  </xsl:template>
  
  <xsl:template match="dbk:inlineequation" mode="default">
    <inline-formula>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </inline-formula>
  </xsl:template>
  
  <xsl:template match="dbk:inlineequation[dbk:alt/@role = 'TeX'][mml:math]" mode="default">
    <disp-formula>
      <xsl:apply-templates select="@*" mode="#current"/>
      <alternatives>
        <xsl:apply-templates select="*" mode="#current"/>
      </alternatives>
    </disp-formula>
  </xsl:template>

  <xsl:function name="jats:is-page-anchor" as="xs:boolean">
    <xsl:param name="anchor" as="element(dbk:anchor)"/>
    <xsl:sequence select="exists($anchor/@xml:id[matches(., '^(cell)?page_[^_]')])"/>
  </xsl:function>
  

  <!-- not useful at this stadium. perhaps if the attribute usage is improved. Then it could become a styled-content element with style-type in a label -->
  <xsl:template match="@hub:numbering-inline-stylename" mode="clean-up"/>
  
  <!-- content-type not valid on ext-link -->
  <xsl:template match="ext-link/@content-type" mode="clean-up">
    <xsl:attribute name="xlink:role" select="."/>
  </xsl:template>
  
  <xsl:template match="sec/@content-type
                      |fn/@content-type
                      |alt-title/@content-type
                      |book-id/@content-type
                      |abstract/@content-type" mode="clean-up">
    <xsl:attribute name="{concat(parent::*/local-name(), '-type')}" select="."/>
  </xsl:template>
  
  <!-- returns major, minor version and suffix of dtd version string -->
  
  <xsl:function name="jats:dtd-version" as="xs:string+">
    <xsl:analyze-string select="$dtd-version" regex="^([\d.]+)(.*)$">
      <xsl:matching-substring>
        <xsl:sequence select="for $version-label in tokenize(regex-group(1), '\.')
                              return xs:string(xs:integer($version-label)),
                              replace(regex-group(2), '^[\p{P}]', '')"/>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  
</xsl:stylesheet>

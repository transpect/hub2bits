# hub2bits

This is a more or less generic yet organically grown Hub→JATS/BITS converter. 
It was commissioned by the Hogrefe group of publishers for their [HoBoTS](https://hobots.hogrefe.com/)
project. This is just a library and depends on certain transpect-modules. For installation, please
see detailed instructions below.

## requirements

Java 1.7 (to run XML Calabash)

## installation

As mentioned above, hub2bits is just a library. So we need to create a frontend project which
includes other needed modules and some infrastructure.

### create directory for frontend project

```
mkdir hub2bits-frontend
cd hub2bits-frontend

```


### get dependencies

```
git clone git@github.com:transpect/calabash-frontend.git --recursive
git clone git@github.com:transpect/hub2bits.git
git clone git@github.com:transpect/cascade.git
git clone git@github.com:transpect/xproc-util.git
git clone git@github.com:transpect/xslt-util.git

```

### create frontend catalog

Create an XML catalog. Transpect operates with canonical URIs that typically starts
with `http://transpect.io/module-name/…`. The XML catalog is used by a catalog resolver
to resolve the URIs to their respective file paths.

```
mkdir xmlcatalog
touch xmlcatalog/catalog.xml
```

Each module provide its own XML catalog. They are connected with nextCatalog statements in
the catalog of the frontend project. Just add the entries into xmlcatalog/catalog.xml:


```
<?xml version="1.0" encoding="UTF-8"?>
<catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">

    <nextCatalog catalog="../cascade/xmlcatalog/catalog.xml"/>
    <nextCatalog catalog="../hub2bits/xmlcatalog/catalog.xml"/>
    <nextCatalog catalog="../xproc-util/xmlcatalog/catalog.xml"/>
    <nextCatalog catalog="../xslt-util/xmlcatalog/catalog.xml"/>

</catalog>

```

### run the pipeline

./calabash-frontend/calabash.bat -i source=myHub.xml -o result=myOutput.xml hub2bits/xpl/hub2bits.xpl

### blame the developers (or create an issue/PR or make an override)

If you work for different customers, you might experience that there is no general-purpose solution
which meet all their needs. We initally developed this module to meet the requirements of the
Hogrefe publishing group. But transpect provides ways to override the standard behaviour of a module.
Feel free to read this [tutorial about configuration cascades](http://transpect.github.io/tutorial.html#dynamic-transformation-pipelines).


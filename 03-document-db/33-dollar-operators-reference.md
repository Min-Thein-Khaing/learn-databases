# MongoDB `$` Operators Reference

MongoDB uses `$` names in several contexts. An operator only works in the
context where it is defined.

```js
{ price: { $gt: 100 } }                    // query predicate
{ $inc: { stock: 1 } }                     // update operator
{ $group: { _id: "$category" } }           // pipeline stage
{ total: { $multiply: ["$price", "$stock"] } } // expression
```

## How to read `$`

| Form | Meaning |
|---|---|
| `$match` | Operator or stage name |
| `"$price"` | Read the `price` field |
| `"$user.name"` | Read an embedded field |
| `"$$variable"` | User or system variable |
| `{ $literal: "$price" }` | Return the text `$price` |

## Query predicates

Used in `find()` filters, update/delete filters, and `$match`.

| Family | Operators |
|---|---|
| Comparison | `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin` |
| Logical | `$and`, `$or`, `$nor`, `$not` |
| Fields/types | `$exists`, `$type`, `$expr`, `$jsonSchema`, `$mod`, `$regex`, `$where` |
| Arrays | `$all`, `$elemMatch`, `$size` |
| Geospatial | `$geoIntersects`, `$geoWithin`, `$near`, `$nearSphere` |
| Bitwise | `$bitsAllClear`, `$bitsAllSet`, `$bitsAnyClear`, `$bitsAnySet` |

For syntax, anchors, options, escaping, and SQL `LIKE` equivalents, see
[Regular expressions in Lesson 3.9](09-query-operators.md#step-4--regex-pattern-matching-on-text).

## Find projection operators

| Operator | Purpose |
|---|---|
| `$` | Return the first matched array element |
| `$elemMatch` | Return the first array element matching conditions |
| `$meta` | Return metadata such as a text score |
| `$slice` | Return part of an array |

## Update operators

| Family | Operators |
|---|---|
| Fields | `$currentDate`, `$inc`, `$min`, `$max`, `$mul`, `$rename`, `$set`, `$setOnInsert`, `$unset` |
| Arrays | `$addToSet`, `$pop`, `$pull`, `$pullAll`, `$push` |
| Array modifiers | `$each`, `$position`, `$slice`, `$sort` |
| Array positions | `$`, `$[]`, `$[identifier]` |
| Bits | `$bit` |

## Aggregation pipeline stages

Stages are top-level objects inside the array passed to `aggregate()`.

| Family | Stages |
|---|---|
| Filter/order/page | `$match`, `$sort`, `$limit`, `$skip`, `$sample` |
| Shape fields | `$project`, `$addFields`, `$set`, `$unset`, `$replaceRoot`, `$replaceWith`, `$redact` |
| Arrays/groups | `$unwind`, `$group`, `$sortByCount`, `$bucket`, `$bucketAuto` |
| Combine data | `$lookup`, `$graphLookup`, `$unionWith`, `$facet` |
| Sequence/window | `$densify`, `$fill`, `$setWindowFields` |
| Count/source | `$count`, `$documents` |
| Write results | `$merge`, `$out` |
| Location | `$geoNear` |
| Search | `$search`, `$searchMeta`, `$vectorSearch`, `$rankFusion` |
| Changes | `$changeStream`, `$changeStreamSplitLargeEvent` |
| Statistics/admin | `$collStats`, `$currentOp`, `$indexStats`, `$listClusterCatalog`, `$listLocalSessions`, `$listSampledQueries`, `$listSearchIndexes`, `$listSessions`, `$planCacheStats`, `$querySettings`, `$queryStats`, `$shardedDataDistribution` |

Some stages require Atlas, a particular MongoDB version, or special
permissions.

## Aggregation expressions

Expressions calculate values inside stages such as `$project`, `$set`,
`$group`, and `$setWindowFields`.

| Family | Operators |
|---|---|
| Arithmetic | `$abs`, `$add`, `$ceil`, `$divide`, `$exp`, `$floor`, `$ln`, `$log`, `$log10`, `$mod`, `$multiply`, `$pow`, `$round`, `$sqrt`, `$subtract`, `$trunc` |
| Comparison | `$cmp`, `$eq`, `$gt`, `$gte`, `$lt`, `$lte`, `$ne` |
| Boolean | `$and`, `$not`, `$or` |
| Conditional | `$cond`, `$ifNull`, `$switch` |
| Arrays | `$arrayElemAt`, `$arrayToObject`, `$concatArrays`, `$filter`, `$first`, `$firstN`, `$in`, `$indexOfArray`, `$isArray`, `$last`, `$lastN`, `$map`, `$maxN`, `$minN`, `$objectToArray`, `$range`, `$reduce`, `$reverseArray`, `$size`, `$slice`, `$sortArray`, `$zip` |
| Objects | `$getField`, `$mergeObjects`, `$setField` |
| Sets | `$allElementsTrue`, `$anyElementTrue`, `$setDifference`, `$setEquals`, `$setIntersection`, `$setIsSubset`, `$setUnion` |
| Strings | `$concat`, `$indexOfBytes`, `$indexOfCP`, `$ltrim`, `$regexFind`, `$regexFindAll`, `$regexMatch`, `$replaceAll`, `$replaceOne`, `$rtrim`, `$split`, `$strcasecmp`, `$strLenBytes`, `$strLenCP`, `$substrBytes`, `$substrCP`, `$toLower`, `$toUpper`, `$trim` |
| Dates | `$dateAdd`, `$dateDiff`, `$dateFromParts`, `$dateFromString`, `$dateSubtract`, `$dateToParts`, `$dateToString`, `$dateTrunc`, `$dayOfMonth`, `$dayOfWeek`, `$dayOfYear`, `$hour`, `$isoDayOfWeek`, `$isoWeek`, `$isoWeekYear`, `$millisecond`, `$minute`, `$month`, `$second`, `$week`, `$year` |
| Conversion/type | `$binarySize`, `$bsonSize`, `$convert`, `$isNumber`, `$toBool`, `$toDate`, `$toDecimal`, `$toDouble`, `$toInt`, `$toLong`, `$toObjectId`, `$toString`, `$toUUID`, `$type` |
| Bitwise | `$bitAnd`, `$bitNot`, `$bitOr`, `$bitXor` |
| Trigonometry | `$acos`, `$acosh`, `$asin`, `$asinh`, `$atan`, `$atan2`, `$atanh`, `$cos`, `$cosh`, `$degreesToRadians`, `$radiansToDegrees`, `$sin`, `$sinh`, `$tan`, `$tanh` |
| Miscellaneous | `$literal`, `$let`, `$meta`, `$rand`, `$sampleRate`, `$function` |

`$function` is deprecated. Prefer built-in expressions.

## Accumulators

Used mainly in `$group` and `$setWindowFields`.

`$accumulator`, `$addToSet`, `$avg`, `$bottom`, `$bottomN`, `$count`,
`$first`, `$firstN`, `$last`, `$lastN`, `$max`, `$maxN`, `$median`,
`$mergeObjects`, `$min`, `$minN`, `$percentile`, `$push`, `$stdDevPop`,
`$stdDevSamp`, `$sum`, `$top`, `$topN`

`$accumulator` is deprecated. Prefer built-in accumulators.

## Window-only operators

Used through `$setWindowFields`:

`$covariancePop`, `$covarianceSamp`, `$denseRank`, `$derivative`,
`$documentNumber`, `$expMovingAvg`, `$integral`, `$linearFill`, `$locf`,
`$rank`, `$shift`

## Same name, different context

| Name | Different uses |
|---|---|
| `$set` | Update a stored field or add a pipeline field |
| `$unset` | Remove a stored field or remove a pipeline field |
| `$in` | Query predicate or expression returning true/false |
| `$size` | Query exact array length or calculate array length |
| `$sum` | Accumulator or expression |
| `$min` / `$max` | Update operators, expressions, and accumulators |
| `$first` / `$last` | Array expressions and accumulators |
| `$count` | Pipeline stage and accumulator |
| `$slice` | Projection, update modifier, and expression |

Always identify the context before interpreting an operator.

## Canonical, version-specific lists

MongoDB adds operators over time. These official pages are authoritative:

- [MongoDB Query Language](https://www.mongodb.com/docs/manual/reference/mql/)
- [Query predicates](https://www.mongodb.com/docs/manual/reference/mql/query-predicates/)
- [Aggregation stages](https://www.mongodb.com/docs/manual/reference/mql/aggregation-stages/)
- [Aggregation expressions](https://www.mongodb.com/docs/manual/reference/operator/aggregation/)
- [Update operators](https://www.mongodb.com/docs/manual/reference/operator/update/)

---
← [Module 3 Conclusion](24-conclusion.md)

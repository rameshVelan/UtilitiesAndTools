//Read JSON File and store into dataframe and pass the DF as argument to the method.

def jsonParser(dfJSON: DataFrame): DataFrame = {
		var df: DataFrame = dfJSON
		var runFlag = true 
		while(runFlag){
		    runFlag = false
			  df.schema.fields.foreach {
          elem =>
				  var fieldNames = df.schema.fields.map(x => x.name)
				  elem.dataType match {
				  
          case arrayType: ArrayType => runFlag = true
					                fieldNames = fieldNames.filter(_!=elem.name) ++ Array("explode_outer(".concat(elem.name).concat(") as ").concat(elem.name))
					                df=df.selectExpr(fieldNames:_*)
				  
          case structType: StructType => runFlag = true
					                 fieldNames = fieldNames.filter(_!=elem.name) ++ structType.fieldNames.map(childname => elem.name.concat(".").concat(childname)
                           .concat(" as ").concat(elem.name).concat("_").concat(childname))
					                 df=df.selectExpr(fieldNames:_*)
                           
				case _ => //println("Other than Array & Struct")
				}
			}
		}
		return df
	}

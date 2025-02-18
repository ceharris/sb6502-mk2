init_error_table

.ifdef CONFIG_SMALL_ERROR
define_error ERR_NOFOR, "NF"
define_error ERR_SYNTAX, "SN"
define_error ERR_NOGOSUB, "RG"
define_error ERR_NODATA, "OD"
define_error ERR_ILLQTY, "FC"
define_error ERR_OVERFLOW, "OV"
define_error ERR_MEMFULL, "OM"
define_error ERR_UNDEFSTAT, "US"
define_error ERR_BADSUBS, "BS"
define_error ERR_REDIMD, "DD"
define_error ERR_ZERODIV, "/0"
define_error ERR_ILLDIR, "ID"
define_error ERR_BADTYPE, "TM"
define_error ERR_STRLONG, "LS"
define_error ERR_FRMCPX, "ST"
define_error ERR_CANTCONT, "CN"
define_error ERR_UNDEFFN, "UF"
.else
define_error ERR_NOFOR, "NEXT without FOR"
define_error ERR_SYNTAX, "Syntax"
define_error ERR_NOGOSUB, "RETURN without GOSUB"
define_error ERR_NODATA, "Out of data"
define_error ERR_ILLQTY, "Illegal quantity"
define_error ERR_OVERFLOW, "Overflow"
define_error ERR_MEMFULL, "Out of memory"
define_error ERR_UNDEFSTAT, "Undefined statement"
define_error ERR_BADSUBS, "Bad subscript"
define_error ERR_REDIMD, "Redimensioned array"
define_error ERR_ZERODIV, "Division by zero"
define_error ERR_ILLDIR, "Illegal direct"
define_error ERR_BADTYPE, "Type mismatch"
define_error ERR_STRLONG, "String too long"
.ifdef CONFIG_FILE
define_error ERR_BADDATA, "File data"
.endif
define_error ERR_FRMCPX, "Formula too complex"
define_error ERR_CANTCONT, "Cannot continue"
define_error ERR_UNDEFFN, "Undefined function"
.endif
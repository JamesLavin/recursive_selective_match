# Changelog for RecursiveSelectiveMatch

## 0.1.5

### 1. Enhancements

  * Previously, match failure messages were printed using IO.inspect(). You can now override the new default behavior of calling Logger.error() on errors and instead maintain the original behavior -- calling IO.inspect() -- by passing an options map (as a third argument) containing `%{io_errors: true}`. (You can also suppress error logging/printing by passing `%{suppress_warnings: true}`)
  * Improved error messages for tuple matching
  * Improved error messages for map matching

### 2. Bug fixes

  * We previously had not correctly implemented matching using `:any_tuple`. It should now work properly.
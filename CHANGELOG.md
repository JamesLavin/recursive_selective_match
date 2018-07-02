# Changelog for RecursiveSelectiveMatch

## 0.2.1

### 1. Enhancements

  * Improve informativeness of error message when expected map key doesn't match actual map key.
  * Add %{full_lists: true} option that ensures actual lists contain no additional list elements not listed in the expected list (by default, lists match if an actual list contains all elements in the expected list, even if additional elements are present)
  * Add %{exact_lists: true} option that ensures every actual list completely matches its expected list. All list elements in actual must be in expected and must be in the same order, and all list elements in expected must be in actual.
  * Improve documentation with example showing `refute RSM.matches?(expected, actual, %{suppress_warnings: true})`

## 0.2.0

### 1. Enhancements

  * Previously, match failure messages were printed using IO.inspect(). You can now override the new default behavior of calling Logger.error() on errors and instead maintain the original behavior -- calling IO.inspect() -- by passing an options map (as a third argument) containing `%{io_errors: true}`. (You can also suppress error logging/printing by passing `%{suppress_warnings: true}`)
  * Improved error messages for tuple matching
  * Improved error messages for map matching

### 2. Bug fixes

  * We previously had not correctly implemented matching using `:any_tuple`. It should now work properly.
# Maintainability Guide: Filtering & Search

To keep the filtering system stable as Alpha Motors grows, follow these conventions.

## 1. Adding a New Filter
When adding a new filter (e.g., "Drive Train"):
1.  **Database**: Add column to `posts` table via migration.
2.  **DTO**: Add property to `FindAllPosts` in `post.dto.ts`. Use `@ApiProperty({ required: false })`.
3.  **Service**: Add the logic to `PostService.findAll`. 
    *   *Convention*: Use `Op.iLike` for strings and `Op.eq` or `stringToBoolean` for flags.
4.  **Frontend Controller**: Add an `Rx` variable to `FilterController`.
5.  **Frontend Search**: Add the variable to `FilterController.buildQueryParams` and add an `ever()` listener in `onInit`.

## 2. Boolean Handling
The API receives all query parameters as **Strings**. 
*   **Always** use the `stringToBoolean()` helper in the backend service.
*   **Never** assume `query.status === true` will work directly from a URL parameter.

## 3. History Management
Brand history is stored locally. 
*   Maximum items: 10.
*   Storage Key: `brand_history`.
*   Resolution: Use `BrandHistoryService` to resolve UUIDs to display objects.

## 4. UI Consistency
*   Use `PostSelectableField` for any filter that opens a BottomSheet.
*   Ensure every new filter has a corresponding chip in `_buildActiveFilterChips` so users can see active state.

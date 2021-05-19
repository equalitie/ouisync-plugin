#ifndef localRepository_h
#define localRepository_h


#include <CallbackManager.h>
#include <string>

#ifdef __cplusplus
extern "C" {
#endif
      // repo_dir is the repository identifier
      void initializeOuisyncRepository(const char* repo_dir);

      void createDir(Dart_Port callbackPort, const char* repo_dir, const char* c_new_directory);
      void readDir(Dart_Port callbackPort, const char* repo_dir, const char* directory_to_read);
      void removeDir(Dart_Port callbackPort, const char* repo_dir, const char* directory_to_remove); //TODO: removeDir
      
      void createFile(Dart_Port callbackPort, const char* repo_dir, const char* c_new_file_path);
      void writeFile(Dart_Port callbackPort, const char* repo_dir, const char* file_path, const char* buffer, size_t size, off_t offset);
      void readFile(Dart_Port callbackPort, const char* repo_dir, const char* file_path, char* buffer, size_t size, off_t offset); //TODO: readFile
      void removeFile(Dart_Port callbackPort, const char* repo_dir, const char* path_file_to_remove); //TODO: removeFile

      void getAttributes(Dart_Port callbackPort, const char* repo_dir, const char  **c_paths, const int size);
#ifdef __cplusplus
}
#endif

#endif /* localRepository_h */

module hello_world::hello_world {
  struct HelloWorldObject has key, store {
    id: UID,
    /// A string contained in the object
    text: string::String
  }

}




export type MeleeType<T> = {
    new : () -> (T),
    initialize : () -> (),
    swing : () -> ()
}

return {}
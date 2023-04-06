open Bap.Std
open Bap_main
open Extension.Syntax
open Extension

include Self()

let library_path = Filename.concat Configuration.sysdatadir "asli"
let prelude lib = Filename.concat lib "prelude.asl"
let specs lib = List.map (fun f -> Filename.concat lib f) [
  "regs.asl";
  "types.asl";
  "arch.asl";
  "arch_instrs.asl";
  "arch_decode.asl";
  "aes.asl";
  "barriers.asl";
  "debug.asl";
  "feature.asl";
  "hints.asl";
  "interrupts.asl";
  "memory.asl";
  "stubs.asl";
  "override.asl";
] 

let disable =
  Configuration.parameter Type.bool "disable"
    ~doc:"Disable the ASL lifter."

let path =
  Configuration.parameter Type.dir "path"
    ~doc:"Path to ASL specifications."

let () = Bap_main.Extension.declare ~doc @@ fun ctxt -> 
  let lib = ctxt--> path in
  let lib = if lib = "" then library_path else lib in
  let prelude = prelude lib in
  let specs = specs lib in
  if ctxt-->disable then Ok () else
  Ok (Asli_lifter.load prelude specs)

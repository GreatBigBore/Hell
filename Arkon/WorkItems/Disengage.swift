import Dispatch

final class Disengage: Dispatchable {
    internal override func launch_() {
        guard let (ch, dp, st) = self.scratch?.getKeypoints() else { fatalError() }
        st.nose.color = .blue
        st.sprite?.color = .red
        Log.L.write("disengage \(six(st.name))", level: 31)

        Log.L.write("Reset engagerKey #0", level: 41)
        precondition(ch.cellShuttle == nil && ch.engagerKey != nil)

        ch.engagerKey = nil
        dp.engage()
    }

}

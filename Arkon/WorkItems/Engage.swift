import Dispatch

enum DebugEngage {
    case nothing, entry, notHotKey, coldKey, running, returned
}

final class Engage: Dispatchable {
    internal override func launch_() {
        guard let (ch, dp, st) = self.scratch?.getKeypoints() else { fatalError() }
        guard let gc = st.gridCell else { fatalError() }

        st.nose.color = .blue
        precondition(ch.cellConnector_ == nil)
        let cellConnector = gc.lock(require: false)

        if !(cellConnector is HotKey) {
            if cellConnector is ColdKey {
                Grid.shared.serialQueue.asyncAfter(deadline: .now() + 0.1) {
                    precondition(((cellConnector as? ColdKey)?.debugDontUseIsLocked ?? true) == true)
                    dp.disengage()
                }
            }
            st.nose.color = .green
            return
        }

        guard let cc = cellConnector as? HotKey else { preconditionFailure() }
        ch.cellConnector_ = cc
        ch.worldStats = World.stats.copy()
        cc.cell.ownerName = st.name
        st.nose.color = .black

        dp.funge()
    }
}
